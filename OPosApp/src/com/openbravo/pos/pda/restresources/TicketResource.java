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

import javax.ws.rs.Consumes;
import javax.ws.rs.DELETE;
import javax.ws.rs.GET;
import javax.ws.rs.POST;
import javax.ws.rs.Path;
import javax.ws.rs.Produces;
import javax.ws.rs.QueryParam;

import com.openbravo.basic.BasicException;
import com.openbravo.pos.forms.DataLogicSales;
import com.openbravo.pos.pda.app.AppViewImpl;
import com.openbravo.pos.sales.DataLogicReceipts;
import com.openbravo.pos.sales.SharedTicketInfo;
import com.openbravo.pos.sales.TaxesLogic;
import com.openbravo.pos.sales.restaurant.Place;
import com.openbravo.pos.ticket.ProductInfoExt;
import com.openbravo.pos.ticket.TaxInfo;
import com.openbravo.pos.ticket.TicketInfo;
import com.openbravo.pos.ticket.TicketLineInfo;

/**
 * 
 * @author axel
 */
@Path("/tickets")
public class TicketResource {

	DataLogicSales dls = AppViewImpl.getBean(DataLogicSales.class);
	DataLogicReceipts dlr = AppViewImpl.getBean(DataLogicReceipts.class);
	TaxesLogic taxesLogic = null;

	public TicketResource() {
		try {
			taxesLogic = new TaxesLogic(dls.getTaxList().list());
		} catch (BasicException e) {
			e.printStackTrace();
		}
	}

	@GET
	@Produces("application/json")
	public List<SharedTicketInfo> getTickets() {
		DataLogicReceipts dls = AppViewImpl.getBean(DataLogicReceipts.class);
		List<SharedTicketInfo> tickets = null;
		try {
			tickets = dls.getSharedTicketList();
		} catch (BasicException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
		return tickets;
	}

	@GET
	@Path("ticket")
	@Produces("application/json")
	public TicketInfo getTicket(@QueryParam("place") String placeId) {
		System.out.println("Place-ID: " + placeId);
		DataLogicReceipts dlr = AppViewImpl.getBean(DataLogicReceipts.class);
		TicketInfo ticket = null;
		try {
			ticket = dlr.getSharedTicket(placeId);
			if (ticket == null) {
				dlr.insertSharedTicket(placeId, new TicketInfo());
				ticket = dlr.getSharedTicket(placeId);
				ticket.setCustomer(null);
				ticket.setTaxes(null);
			}
		} catch (BasicException e) {
			e.printStackTrace();
		}
		return ticket;
	}

	@DELETE
	@Path("/deleteTicketIfEmpty")
	public void deleteTicketIfEmpty(@QueryParam("place") String placeId) {
		DataLogicReceipts dlr = AppViewImpl.getBean(DataLogicReceipts.class);
		try {
			TicketInfo ticket = dlr.getSharedTicket(placeId);
			if (ticket != null && ticket.getLines().isEmpty()) {
				dlr.deleteSharedTicket(placeId);
			}
		} catch (BasicException ex) {
			ex.printStackTrace();
		}
	}

	@POST
	@Path("ticketProducts")
	@Consumes("application/json")
	public void addToTicket(TicketAddition ticketAdd) {
		DataLogicReceipts dlr = AppViewImpl.getBean(DataLogicReceipts.class);
		try {
			TicketInfo ticket = dlr.getSharedTicket(ticketAdd.getTicketId());
			for (TicketLineInfo ticketInfo : ticket.getLines()) {
				ticketInfo.setProperty("sendStatus", "Yes");
			}
			for (String productId : ticketAdd.getProductIds()) {
				int idx = productId.indexOf("#");
				String option = null;
				if (idx > 0) {
					option = productId.substring(idx + 1);
					productId = productId.substring(0, idx);
				}
				DataLogicSales dls = AppViewImpl.getBean(DataLogicSales.class);
				ProductInfoExt product = dls.getProductInfo(productId);

				TaxInfo tax = taxesLogic.getTaxInfo(product.getTaxCategoryID(),
						null);
				TicketLineInfo ticketLine = new TicketLineInfo(product,
						product.getPriceSell(), tax, (Properties) product
								.getProperties().clone());
				ticketLine.setProperty("sendStatus", "No");
				if (option != null) {
					ticketLine.setProperty("product.option", option);
				} else {
					ticketLine.setProperty("product.option", "");
				}
				String detailText = null;
				Properties productProperties = product.getProperties();
				if (productProperties != null) {
					detailText = (String) productProperties
							.getProperty("detailText");
				}
				if (detailText != null) {
					ticketLine.setProperty("product.detailText", detailText);
				} else {
					ticketLine.setProperty("product.detailText", "");
				}
				String printer = null;
				if (productProperties != null) {
					printer = (String) product.getProperty("printer");
				}
				if (printer != null) {
					ticketLine.setProperty("product.printer", printer);
				} else {
					ticketLine.setProperty("product.printer", "");
				}
				ticket.addLine(ticketLine);
			}
   			dlr.updateSharedTicket(ticketAdd.getTicketId(), ticket);
		} catch (BasicException e) {
			e.printStackTrace();
		}
	}

	@POST
	@Path("deleteTicketProducts")
	@Consumes("application/json")
	public void deleteTicketProducts(TicketAddition ticketAdd) {
		try {
			TicketInfo ticket = dlr.getSharedTicket(ticketAdd.getTicketId());
			List<TicketLineInfo> linesToRemove = new ArrayList<TicketLineInfo>();
			for (TicketLineInfo ticketInfo : ticket.getLines()) {
				if (ticketAdd.getProductIds().contains(
						ticketInfo.getProductID())) {
					linesToRemove.add(ticketInfo);
					ticketAdd.getProductIds().remove(ticketInfo.getProductID());
				}
			}
			for (TicketLineInfo line : linesToRemove) {
				ticket.getLines().remove(line);
			}
			int i = 0;
			for (TicketLineInfo line : ticket.getLines()) {
				// TODO: fix this!!
				// line.setM_iLine(i++);
			}
			dlr.updateSharedTicket(ticketAdd.getTicketId(), ticket);
		} catch (BasicException e) {
			e.printStackTrace();
		}
	}

	@POST
	@Path("sendTicketProducts")
	@Consumes("application/json")
	public void sendTicketProducts(TicketAddition ticketAdd) {
		List<String> newProducts = ticketAdd.getProductIds();
		TicketInfo ticket = dlr.getSharedTicket(ticketAdd.getTicketId());
		Set<String> printers = new HashSet<String>();
		int size = ticket.getLines().size();
		int addedSize = ticketAdd.getProductIds().size();
		for (int i = size - 1; i >= size - addedSize; i--) {
			TicketLineInfo ticketInfo = ticket.getLines().get(i);
			if (newProducts.contains(ticketInfo.getProductID())) {
				ticketInfo.setProperty("sendStatus", "No");
				newProducts.remove(ticketInfo.getProductID());

				String printerName = ticketInfo.getProperty(
						"product.printer");
				System.out.println("New product: "
						+ ticketInfo
								.getProperty("product.name") + " on printer "
						+ printerName);
				String detailText = ticketInfo.getProperty(
						"product.detailText");
				System.out.println("detailText["
						+ (detailText == null ? "isNull" : "notNull") + "]: "
						+ detailText);
				String option = ticketInfo.getProperty(
						"product.option");
				System.out.println("Option["
						+ (option == null ? "isNull" : "notNull") + "]: "
						+ option);
				if (printerName != null && !printerName.equals("")) {
					printers.add(printerName);
				}
			} else {
				ticketInfo.setProperty("sendStatus", "Yes");
			}
		}
		Place place = manager.findPlaceById(ticketAdd.getTicketId());
		TestPrint tp = new TestPrint();
		for (String printerName : printers) {
			System.out.println("printing lines for printer " + printerName);
			tp.PrintPDATicket(place.getName(), ticket, printerName);
		}
	}

	// @POST
	// @Path("closeTicketForItems")
	// @Consumes("application/json")
	// public void closeTicketForItems(TicketAddition ticketAdd) {
	// List<String> newProducts = ticketAdd.getProductIds();
	// TicketInfo ticket = manager.findTicket(ticketAdd.getTicketId());
	// List<TicketLineInfo> ticketLines = new ArrayList<TicketLineInfo>();
	// List<TicketLineInfo> remainingTicketLines = new
	// ArrayList<TicketLineInfo>();
	// for (TicketLineInfo ticketInfo : ticket.getLines()) {
	// if (newProducts.contains(ticketInfo.getProductid())) {
	// newProducts.remove(ticketInfo.getProductid());
	// ticketLines.add(ticketInfo);
	// } else {
	// remainingTicketLines.add(ticketInfo);
	// }
	// }
	// if (ticketLines.size() > 0) {
	// ticket.setM_aLines(ticketLines);
	// TicketDAO dao = new TicketDAO();
	// dao.updateTicket(ticketAdd.getTicketId(), ticket);
	//
	// closeTicket(ticketAdd.getTicketId());
	//
	// TicketInfo newTicket = getTicket(ticketAdd.getTicketId());
	// newTicket.setM_aLines(remainingTicketLines);
	// dao.updateTicket(ticketAdd.getTicketId(), newTicket);
	// }
	// }

	@DELETE
	@Path("/closeTicket")
	public void closeTicket(@QueryParam("place") String place) {
		System.out.println("TicketId: " + place);
		TicketInfo ticket = getTicket(place);

		System.out.println("TicketId (Id): " + ticket.getId());
		CheckoutHelper helper = new CheckoutHelper();
		try {
			helper.checkout(ticket, place);
		} catch (BasicException e) {
			e.printStackTrace();
		}
	}

	@DELETE
	@Path("/moveTicket")
	public void moveTicket(@QueryParam("fromTable") String fromTable,
			@QueryParam("toTable") String toTable) {
		DataLogicReceipts dlr = AppViewImpl.getBean(DataLogicReceipts.class);

		try {
			TicketInfo fromTicket = dlr.getSharedTicket(fromTable);
			TicketInfo toTicket = dlr.getSharedTicket(toTable);

			List<TicketLineInfo> ticketLines = fromTicket.getLines();
			for (TicketLineInfo ticketLine : ticketLines) {
				toTicket.addLine(ticketLine);
			}

			dlr.updateSharedTicket(toTable, toTicket);
			dlr.deleteSharedTicket(fromTable);
		} catch (BasicException ex) {
			ex.printStackTrace();
		}
	}
}
