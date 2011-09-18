package com.openbravo.pos.pda.bean;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Properties;
import java.util.Set;

import javax.annotation.PostConstruct;
import javax.ejb.Stateless;
import javax.ws.rs.QueryParam;

import com.openbravo.basic.BasicException;
import com.openbravo.data.gui.ListKeyed;
import com.openbravo.data.loader.SentenceList;
import com.openbravo.pos.forms.DataLogicSales;
import com.openbravo.pos.forms.DataLogicSystem;
import com.openbravo.pos.pda.app.AppViewImpl;
import com.openbravo.pos.pda.datalogic.DataLogicFloors;
import com.openbravo.pos.printer.TicketParser;
import com.openbravo.pos.printer.TicketPrinterException;
import com.openbravo.pos.sales.DataLogicReceipts;
import com.openbravo.pos.sales.SharedTicketInfo;
import com.openbravo.pos.sales.TaxesLogic;
import com.openbravo.pos.scripting.ScriptEngine;
import com.openbravo.pos.scripting.ScriptException;
import com.openbravo.pos.scripting.ScriptFactory;
import com.openbravo.pos.ticket.ProductInfoExt;
import com.openbravo.pos.ticket.TaxInfo;
import com.openbravo.pos.ticket.TicketInfo;
import com.openbravo.pos.ticket.TicketLineInfo;

@Stateless
public class TicketsBean {
	
	AppViewImpl appView;

	
	DataLogicSystem dlSystem = null;
	DataLogicSales dls = null;
	DataLogicReceipts dlr = null;
	DataLogicFloors dlf = null;
	
	
	TaxesLogic taxesLogic = null;
	TicketParser ticketParser = null;

	@PostConstruct
	public void init() {
		appView = AppViewImpl.getInstance();
		this.dlr = appView.getBean(DataLogicReceipts.class);
		this.dlSystem = appView.getBean(DataLogicSystem.class);
		this.dls = appView.getBean(DataLogicSales.class);
		this.dlf = appView.getBean(DataLogicFloors.class);
				
		try {
			taxesLogic = new TaxesLogic(dls.getTaxList().list());
			ticketParser = new TicketParser(appView
					.getDeviceTicket(), dlSystem);
		} catch (BasicException e) {
			e.printStackTrace();
		}
	}


	public List<SharedTicketInfo> getTickets() {
		List<SharedTicketInfo> tickets = null;
		try {
			tickets = dlr.getSharedTicketList();
		} catch (BasicException e) {
			e.printStackTrace();
		}
		return tickets;
	}
	
	
	public TicketInfo getTicket(String placeId) {
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

	public void deleteTicketIfEmpty(String placeId) {
		try {
			TicketInfo ticket = dlr.getSharedTicket(placeId);
			if (ticket != null && ticket.getLines().isEmpty()) {
				dlr.deleteSharedTicket(placeId);
			}
		} catch (BasicException ex) {
			ex.printStackTrace();
		}
	}

	public void addToTicket(String placeId, TicketAddition ticketAdd) {
		try {
			TicketInfo ticket = dlr.getSharedTicket(placeId);
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
			dlr.updateSharedTicket(placeId, ticket);
		} catch (BasicException e) {
			e.printStackTrace();
		}
	}

	public void deleteTicketLine(String placeId, int lineIndex) {
		try {
			TicketInfo ticket = dlr.getSharedTicket(placeId);
			ticket.removeLine(lineIndex);
			dlr.updateSharedTicket(placeId, ticket);
		} catch (BasicException e) {
			e.printStackTrace();
		}
	}

	public void sendTicketProducts(String placeId, TicketAddition ticketAdd) {
		try {
			List<String> newProducts = ticketAdd.getProductIds();
			TicketInfo ticket = dlr.getSharedTicket(placeId);
			Set<String> printers = new HashSet<String>();
			int size = ticket.getLines().size();
			int addedSize = ticketAdd.getProductIds().size();
			for (int i = size - 1; i >= size - addedSize; i--) {
				TicketLineInfo ticketInfo = ticket.getLines().get(i);
				if (newProducts.contains(ticketInfo.getProductID())) {
					ticketInfo.setProperty("sendStatus", "No");
					newProducts.remove(ticketInfo.getProductID());

					String printerName = ticketInfo
							.getProperty("product.printer");
					System.out.println("New product: "
							+ ticketInfo.getProperty("product.name")
							+ " on printer " + printerName);
					String detailText = ticketInfo
							.getProperty("product.detailText");
					System.out.println("detailText["
							+ (detailText == null ? "isNull" : "notNull")
							+ "]: " + detailText);
					String option = ticketInfo.getProperty("product.option");
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

			String place = dlSystem.findLocationName(placeId);
			for (String printerName : printers) {
				System.out.println("printing lines for printer " + printerName);
				printPDATicket(place, ticket, printerName);
			}
		} catch (BasicException e) {
			e.printStackTrace();
		}
	}

	public void closeTicketForItems(String placeId, TicketAddition ticketAdd) {
		List<String> newProducts = ticketAdd.getProductIds();
		try {
			TicketInfo ticket = dlr.getSharedTicket(placeId);
			List<TicketLineInfo> ticketLines = new ArrayList<TicketLineInfo>();
			List<TicketLineInfo> remainingTicketLines = new ArrayList<TicketLineInfo>();
			for (TicketLineInfo ticketInfo : ticket.getLines()) {
				if (newProducts.contains(ticketInfo.getProductID())) {
					newProducts.remove(ticketInfo.getProductID());
					ticketLines.add(ticketInfo);
				} else {
					remainingTicketLines.add(ticketInfo);
				}
			}
			if (ticketLines.size() > 0) {
				ticket.setLines(ticketLines);
				dlr.updateSharedTicket(placeId, ticket);

				closeTicket(placeId);

				TicketInfo newTicket = getTicket(placeId);
				newTicket.setLines(remainingTicketLines);
				dlr.updateSharedTicket(placeId, newTicket);
			}
		} catch (BasicException ex) {
			ex.printStackTrace();
		}
	}

	public void closeTicket(String placeId) {
		TicketInfo ticket = getTicket(placeId);

		CheckoutHelper helper = new CheckoutHelper();
		try {
			helper.checkout(ticket, placeId);
		} catch (BasicException e) {
			e.printStackTrace();
		}
	}

	public void moveTicket(@QueryParam("fromTable") String fromTable,
			@QueryParam("toTable") String toTable) {

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

	public boolean printPDATicket(String place, TicketInfo ticket,
			String printerName) {
		String sresource = dlSystem.getResourceAsXML("Printer." + printerName);
		SentenceList sentTax = dls.getTaxList();
		try {
			ListKeyed<TaxInfo> taxcollection = new ListKeyed<TaxInfo>(
					sentTax.list());
			if (sresource != null) {
				try {
					ScriptEngine script = ScriptFactory
							.getScriptEngine(ScriptFactory.VELOCITY);
					script.put("taxes", taxcollection);
					script.put("taxeslogic", taxesLogic);
					script.put("ticket", ticket);
					script.put("place", place);
					ticketParser.printTicket(script.eval(sresource).toString());
				} catch (ScriptException e) {
					e.printStackTrace();
					return false;
				} catch (TicketPrinterException e) {
					e.printStackTrace();
					return false;
				}
			}
		} catch (BasicException e) {
			e.printStackTrace();
			return false;
		}

		return true;
	}	
}
