/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */

package com.openbravo.pos.pda.restresources;

import java.util.ArrayList;
import java.util.List;
import java.util.Properties;

import javax.ws.rs.Consumes;
import javax.ws.rs.POST;
import javax.ws.rs.Path;

import com.openbravo.basic.BasicException;
import com.openbravo.pos.forms.DataLogicSales;
import com.openbravo.pos.forms.DataLogicSystem;
import com.openbravo.pos.pda.app.AppViewImpl;
import com.openbravo.pos.pda.datalogic.DataLogicFloors;
import com.openbravo.pos.printer.TicketParser;
import com.openbravo.pos.sales.DataLogicReceipts;
import com.openbravo.pos.sales.TaxesLogic;
import com.openbravo.pos.ticket.ProductInfoExt;
import com.openbravo.pos.ticket.TaxInfo;
import com.openbravo.pos.ticket.TicketInfo;
import com.openbravo.pos.ticket.TicketLineInfo;

/**
 * 
 * @author axel
 */
@Path("/tickets")
public class TicketItemResource {

	DataLogicSystem dlSystem = AppViewImpl.getBean(DataLogicSystem.class);
	DataLogicSales dls = AppViewImpl.getBean(DataLogicSales.class);
	DataLogicReceipts dlr = AppViewImpl.getBean(DataLogicReceipts.class);
	DataLogicFloors dlf = AppViewImpl.getBean(DataLogicFloors.class);
	TaxesLogic taxesLogic = null;
	TicketParser ticketParser = null;

	public TicketItemResource() {
		try {
			taxesLogic = new TaxesLogic(dls.getTaxList().list());
			ticketParser = new TicketParser(AppViewImpl.getInstance()
					.getDeviceTicket(), dlSystem);
		} catch (BasicException e) {
			e.printStackTrace();
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
			dlr.updateSharedTicket(ticketAdd.getTicketId(), ticket);
		} catch (BasicException e) {
			e.printStackTrace();
		}
	}

}
