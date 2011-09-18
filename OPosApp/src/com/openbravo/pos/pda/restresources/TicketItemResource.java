/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */

package com.openbravo.pos.pda.restresources;

import javax.ws.rs.Consumes;
import javax.ws.rs.DELETE;
import javax.ws.rs.GET;
import javax.ws.rs.Produces;
import javax.ws.rs.core.MediaType;
import javax.ws.rs.core.Response;

import com.openbravo.pos.pda.bean.TicketsBean;
import com.openbravo.pos.ticket.TicketLineInfo;

/**
 * 
 * @author axel
 */
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class TicketItemResource {

	TicketsBean bean;
	String placeId;
	int lineIndex;

	public TicketItemResource(TicketsBean bean, String placeId, int lineIndex) {
		this.bean = bean;
		this.placeId = placeId;
		this.lineIndex = lineIndex;
	}

	@GET
	public TicketLineInfo getTicketLine() {
		return bean.getTicket(placeId).getLine(lineIndex);
	}
	
	@DELETE
	public Response deleteTicketLine() {
		bean.deleteTicketLine(placeId, lineIndex);
		return Response.ok().build();
	}
}
