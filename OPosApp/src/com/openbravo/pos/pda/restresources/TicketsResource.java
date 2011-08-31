/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */

package com.openbravo.pos.pda.restresources;

import java.util.List;

import javax.ws.rs.GET;
import javax.ws.rs.Path;
import javax.ws.rs.Produces;

import com.openbravo.basic.BasicException;
import com.openbravo.pos.pda.app.AppViewImpl;
import com.openbravo.pos.sales.DataLogicReceipts;
import com.openbravo.pos.sales.SharedTicketInfo;

/**
 * 
 * @author axel
 */
@Path("/tickets")
public class TicketsResource {

	DataLogicReceipts dlr = AppViewImpl.getBean(DataLogicReceipts.class);

	@GET
	@Produces("application/json")
	public List<SharedTicketInfo> getTickets() {
		List<SharedTicketInfo> tickets = null;
		try {
			tickets = dlr.getSharedTicketList();
		} catch (BasicException e) {
			e.printStackTrace();
		}
		return tickets;
	}

}
