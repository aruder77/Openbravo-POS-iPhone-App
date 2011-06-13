/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */

package com.openbravo.pos.pda.restresources;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Properties;
import java.util.Set;

import javax.ejb.Singleton;
import javax.ws.rs.Consumes;
import javax.ws.rs.DELETE;
import javax.ws.rs.GET;
import javax.ws.rs.POST;
import javax.ws.rs.Path;
import javax.ws.rs.Produces;
import javax.ws.rs.QueryParam;

import com.openbravo.basic.BasicException;
import com.openbravo.pos.pda.bo.RestaurantManager;
import com.openbravo.pos.pda.dao.TaxDAO;
import com.openbravo.pos.pda.dao.TicketDAO;
import com.openbravo.pos.ticket.Place;
import com.openbravo.pos.ticket.ProductInfo;
import com.openbravo.pos.ticket.TaxInfo;
import com.openbravo.pos.ticket.TicketAddition;
import com.openbravo.pos.ticket.TicketInfo;
import com.openbravo.pos.ticket.TicketLineInfo;

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
				System.out.println("Place ID: " + place.getId()
						+ " Ticket ID: " + ticket.getId() + "#"
						+ ticket.getName());
				ticket.setCustomer(null);
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
		System.out.println("Place-ID: " + placeId);
		TicketInfo ticket = manager.findTicket(placeId);
		if (ticket != null) {
			ticket.setCustomer(null);
			ticket.setTaxes(null);
		} else {
			manager.initTicket(placeId);
			ticket = manager.findTicket(placeId);
			ticket.setCustomer(null);
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
			TicketLineInfo ticketLine = new TicketLineInfo(product,
					product.getPriceSell(), tax);
			ticketLine.getAttributes().setProperty("sendStatus", "No");
			if (option != null) {
				ticketLine.getAttributes()
						.setProperty("product.option", option);
			} else {
				ticketLine.getAttributes().setProperty("product.option", "");
			}
			String detailText = null;
			Properties productProperties = product.getAttributes();
			if (productProperties != null) {
				detailText = (String) productProperties
						.getProperty("detailText");
			}
			if (detailText != null) {
				ticketLine.getAttributes().setProperty("product.detailText",
						detailText);
			} else {
				ticketLine.getAttributes()
						.setProperty("product.detailText", "");
			}
			String printer = null;
			if (productProperties != null) {
				printer = (String) product.getAttributes().get("printer");
			}
			if (printer != null) {
				ticketLine.getAttributes().setProperty("product.printer",
						printer);
			} else {
				ticketLine.getAttributes().setProperty("product.printer", "");
			}
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
		for (TicketLineInfo line : linesToRemove) {
			ticket.getLines().remove(line);
		}
                int i = 0;
                for (TicketLineInfo line : ticket.getLines()) {
                    line.setM_iLine(i++);
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
		Set<String> printers = new HashSet<String>();
		for (TicketLineInfo ticketInfo : ticket.getLines()) {
			if (newProducts.contains(ticketInfo.getProductid())) {
				ticketInfo.getAttributes().setProperty("sendStatus", "No");
				newProducts.remove(ticketInfo.getProductid());

				String printerName = ticketInfo.getAttributes().getProperty(
						"product.printer");
				System.out.println("New product: "
						+ ticketInfo.getAttributes()
								.getProperty("product.name") + " on printer "
						+ printerName);
				String detailText = ticketInfo.getAttributes().getProperty(
						"product.detailText");
				System.out.println("detailText["
						+ (detailText == null ? "isNull" : "notNull") + "]: "
						+ detailText);
				String option = ticketInfo.getAttributes().getProperty(
						"product.option");
				System.out.println("Option["
						+ (option == null ? "isNull" : "notNull") + "]: "
						+ option);
				if (printerName != null && !printerName.equals("")) {
					printers.add(printerName);
				}
			} else {
				ticketInfo.getAttributes().setProperty("sendStatus", "Yes");
			}
		}
		Place place = manager.findPlaceById(ticketAdd.getTicketId());
		TestPrint tp = new TestPrint();
		for (String printerName : printers) {
			System.out.println("printing lines for printer " + printerName);
			tp.PrintPDATicket(place.getName(), ticket, printerName);
		}
	}

	@POST
	@Path("closeTicketForItems")
	@Consumes("application/json")
	public void closeTicketForItems(TicketAddition ticketAdd) {
		List<String> newProducts = ticketAdd.getProductIds();
		TicketInfo ticket = manager.findTicket(ticketAdd.getTicketId());
		List<TicketLineInfo> ticketLines = new ArrayList<TicketLineInfo>();
		List<TicketLineInfo> remainingTicketLines = new ArrayList<TicketLineInfo>();
		for (TicketLineInfo ticketInfo : ticket.getLines()) {
			if (newProducts.contains(ticketInfo.getProductid())) {
				newProducts.remove(ticketInfo.getProductid());
				ticketLines.add(ticketInfo);
			} else {
				remainingTicketLines.add(ticketInfo);
			}
		}
		if (ticketLines.size() > 0) {
			ticket.setM_aLines(ticketLines);
			TicketDAO dao = new TicketDAO();
			dao.updateTicket(ticketAdd.getTicketId(), ticket);

			closeTicket(ticketAdd.getTicketId());

			TicketInfo newTicket = getTicket(ticketAdd.getTicketId());
			newTicket.setM_aLines(remainingTicketLines);
			dao.updateTicket(ticketAdd.getTicketId(), newTicket);
		}
	}

	@DELETE
	@Path("/closeTicket")
	public void closeTicket(@QueryParam("place") String place) {
		System.out.println("TicketId: " + place);
		TicketInfo ticket = manager.findTicket(place);
		CheckoutHelper helper = new CheckoutHelper();
		try {
			helper.checkout(ticket, place);
		} catch (BasicException e) {
			e.printStackTrace();
		}
	}
	
	@DELETE
	@Path("/moveTicket")
	public void moveTicket(@QueryParam("fromTable") String fromTable, @QueryParam("toTable") String toTable) {
		TicketInfo fromTicket = manager.findTicket(fromTable);
		TicketInfo toTicket = getTicket(toTable);
		
		List<TicketLineInfo> ticketLines = fromTicket.getLines();
		for (TicketLineInfo ticketLine: ticketLines) {
			toTicket.addLine(ticketLine);
		}
		
		TicketDAO dao = new TicketDAO();
		dao.updateTicket(toTable, toTicket);
		
		manager.deleteTicket(fromTable);
	}
}
