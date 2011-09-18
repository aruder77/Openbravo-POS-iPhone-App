/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */

package com.openbravo.pos.pda.restresources;

import java.util.List;

import javax.ejb.Stateless;
import javax.inject.Inject;
import javax.ws.rs.Consumes;
import javax.ws.rs.GET;
import javax.ws.rs.Path;
import javax.ws.rs.PathParam;
import javax.ws.rs.Produces;
import javax.ws.rs.core.MediaType;

import com.openbravo.pos.pda.bean.TicketsBean;
import com.openbravo.pos.sales.SharedTicketInfo;

/**
 * 
 * @author axel
 */
@Stateless
@Path("/tickets")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class TicketsResource {

	@Inject
	TicketsBean bean;
	
	@GET
	public List<SharedTicketInfo> getTickets() {
		return bean.getTickets();
	}
	
	@Path("/{placeId}")
	public TicketResource getTicket(@PathParam("placeId") String placeId) {
		return new TicketResource(bean, placeId);
	}


}
