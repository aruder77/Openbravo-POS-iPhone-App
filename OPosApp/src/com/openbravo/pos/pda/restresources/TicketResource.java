/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */

package com.openbravo.pos.pda.restresources;

import javax.ejb.Stateless;
import javax.ws.rs.Consumes;
import javax.ws.rs.DELETE;
import javax.ws.rs.GET;
import javax.ws.rs.POST;
import javax.ws.rs.Path;
import javax.ws.rs.PathParam;
import javax.ws.rs.Produces;
import javax.ws.rs.QueryParam;
import javax.ws.rs.core.MediaType;
import javax.ws.rs.core.Response;

import com.openbravo.pos.pda.bean.TicketAddition;
import com.openbravo.pos.pda.bean.TicketsBean;
import com.openbravo.pos.ticket.TicketInfo;

/**
 * 
 * @author axel
 */
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class TicketResource {

	TicketsBean bean;
	String placeId;

	public TicketResource(TicketsBean bean, String placeId) {
		this.placeId = placeId;
		this.bean = bean;
	}

	@Path("/{lineIndex}")
	public TicketItemResource getTicketLine(
			@PathParam("lineIndex") int lineIndex) {
		return new TicketItemResource(this.bean, this.placeId, lineIndex);
	}

	@GET
	public TicketInfo getTicket() {
		return bean.getTicket(this.placeId);
	}

	@DELETE
	public Response deleteTicketIfEmpty() {
		bean.deleteTicketIfEmpty(this.placeId);
		return Response.ok().build();
	}

	@POST
	@Path("addProducts")
	public Response addToTicket(TicketAddition ticketAdd) {
		bean.addToTicket(this.placeId, ticketAdd);
		return Response.ok().build();
	}

	@POST
	@Path("sendTicketProducts")
	public Response sendTicketProducts(TicketAddition ticketAdd) {
		bean.sendTicketProducts(this.placeId, ticketAdd);
		return Response.ok().build();
	}

	@POST
	@Path("closeTicketForItems")
	public Response closeTicketForItems(TicketAddition ticketAdd) {
		bean.closeTicketForItems(this.placeId, ticketAdd);
		return Response.ok().build();
	}

	@POST
	@Path("/closeTicket")
	public Response closeTicket() {
		bean.closeTicket(this.placeId);
		return Response.ok().build();
	}

	@POST
	@Path("/moveTicket")
	public Response moveTicket(@QueryParam("toTable") String toTable) {
		bean.moveTicket(this.placeId, toTable);
		return Response.ok().build();
	}
}
