/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */

package com.openbravo.pos.pda.restresources;

import com.openbravo.pos.pda.bo.RestaurantManager;
import com.openbravo.pos.pda.dao.TaxDAO;
import com.openbravo.pos.pda.dao.TicketDAO;
import com.openbravo.pos.ticket.Place;
import com.openbravo.pos.ticket.ProductInfo;
import com.openbravo.pos.ticket.TaxInfo;
import com.openbravo.pos.ticket.TicketAddition;
import com.openbravo.pos.ticket.TicketInfo;
import com.openbravo.pos.ticket.TicketLineInfo;
import java.util.ArrayList;
import java.util.List;
import javax.ejb.Singleton;
import javax.ws.rs.Consumes;
import javax.ws.rs.DELETE;
import javax.ws.rs.GET;
import javax.ws.rs.POST;
import javax.ws.rs.Path;
import javax.ws.rs.Produces;
import javax.ws.rs.QueryParam;

/**
 *
 * @author axel
 */
@Singleton
@Path("/tickets")
public class TicketResource {

    RestaurantManager manager = new RestaurantManager();

    @GET
    @Produces("application/json")
    public List<TicketInfo> getTickets() {
        List<Place> places = manager.findAllPlaces(manager.findTheFirstFloor());
        List<TicketInfo> tickets = new ArrayList<TicketInfo>();
        for (Place place : places) {
            TicketInfo ticket = manager.findTicket(place.getId());
            if (ticket != null) {
                System.out.println("Place ID: " + place.getId() + " Ticket ID: " + ticket.getM_sId() + "#" + ticket.getName());
                ticket.setM_Customer(null);
                ticket.setTaxes(null);
                tickets.add(ticket);
            }
        }
        return tickets;
    }


    @GET
    @Path("ticket")
    @Produces("application/json")
    public TicketInfo getTicket(@QueryParam("place") String placeId) {
        TicketInfo ticket = manager.findTicket(placeId);
        if (ticket != null) {
            ticket.setM_Customer(null);
            ticket.setTaxes(null);
        } else {
            manager.initTicket(placeId);
            ticket = manager.findTicket(placeId);
            ticket.setM_Customer(null);
            ticket.setTaxes(null);
        }
        return ticket;
    }

    @DELETE
    @Path("/deleteTicketIfEmpty")
    public void deleteTicketIfEmpty(@QueryParam("place") String placeId) {
        TicketInfo ticket = manager.findTicket(placeId);
        if (ticket != null && ticket.getLines().isEmpty()) {
            manager.deleteTicket(placeId);
        }
    }


    @POST
    @Path("ticketProducts")
    @Consumes("application/json")
    public void addToTicket(TicketAddition ticketAdd) {
        TicketInfo ticket = manager.findTicket(ticketAdd.getTicketId());
        for (TicketLineInfo ticketInfo : ticket.getLines()) {
            ticketInfo.getAttributes().setProperty("sendStatus", "Yes");
        }
        for (String productId : ticketAdd.getProductIds()) {
            int idx = productId.indexOf("#");
            String option = null;
            if (idx > 0) {
                option = productId.substring(idx + 1);
                productId = productId.substring(0, idx);
            }
            ProductInfo product = manager.findProductById(productId);
            String taxCat = product.getTaxcat();
            TaxDAO taxDao = new TaxDAO();
            TaxInfo tax = taxDao.getTax(taxCat);
            TicketLineInfo ticketLine = new TicketLineInfo(product, product.getPriceSell(), tax);
            ticketLine.getAttributes().setProperty("sendStatus", "No");
            ticketLine.getAttributes().setProperty("product.option", option);
            ticket.addLine(ticketLine);
        }
        TicketDAO dao = new TicketDAO();
        dao.updateTicket(ticketAdd.getTicketId(), ticket);
    }

    @POST
    @Path("deleteTicketProducts")
    @Consumes("application/json")
    public void deleteTicketProducts(TicketAddition ticketAdd) {
        TicketInfo ticket = manager.findTicket(ticketAdd.getTicketId());
        List<TicketLineInfo> linesToRemove = new ArrayList<TicketLineInfo>();
        for (TicketLineInfo ticketInfo : ticket.getLines()) {
            if (ticketAdd.getProductIds().contains(ticketInfo.getProductid())) {
                linesToRemove.add(ticketInfo);
                ticketAdd.getProductIds().remove(ticketInfo.getProductid());
            }
        }
        for (TicketLineInfo line: linesToRemove) {
            ticket.getLines().remove(line);
        }
        TicketDAO dao = new TicketDAO();
        dao.updateTicket(ticketAdd.getTicketId(), ticket);
    }

    @POST
    @Path("sendTicketProducts")
    @Consumes("application/json")
    public void sendTicketProducts(TicketAddition ticketAdd) {
        List<String> newProducts = ticketAdd.getProductIds();
        TicketInfo ticket = manager.findTicket(ticketAdd.getTicketId());
        for (TicketLineInfo ticketInfo : ticket.getLines()) {
            if (newProducts.contains(ticketInfo.getProductid())) {
                ticketInfo.getAttributes().setProperty("sendStatus", "No");
                newProducts.remove(ticketInfo.getProductid());
            } else {
                ticketInfo.getAttributes().setProperty("sendStatus", "Yes");
            }
        }
        Place place = manager.findPlaceById(ticketAdd.getTicketId());
        TestPrint tp = new TestPrint();
        tp.PrintPDATicket(place.getName(), ticket);
    }
}
