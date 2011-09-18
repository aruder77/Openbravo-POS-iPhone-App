package com.openbravo.pos.pda.bean;

import java.util.ArrayList;
import java.util.Date;
import java.util.List;

import com.openbravo.basic.BasicException;
import com.openbravo.pos.forms.DataLogicSales;
import com.openbravo.pos.payment.PaymentInfo;
import com.openbravo.pos.payment.PaymentInfoCash;
import com.openbravo.pos.pda.app.AppViewImpl;
import com.openbravo.pos.sales.TaxesException;
import com.openbravo.pos.sales.TaxesLogic;
import com.openbravo.pos.ticket.TicketInfo;

public class CheckoutHelper {
	
	AppViewImpl appView;

	public void checkout(TicketInfo ticket, String place) throws BasicException {
		appView = AppViewImpl.getInstance();
		DataLogicSales dlSales = appView.getBean(DataLogicSales.class);

		try {
			// reset the payment info
			TaxesLogic taxesLogic = new TaxesLogic(dlSales.getTaxList().list());
			taxesLogic.calculateTaxes(ticket);
			if (ticket.getTotal() >= 0.0) {
				ticket.resetPayments(); // Only reset if is sale
			}

			// assign the payments selected and calculate taxes.
			List<PaymentInfo> payments = new ArrayList<PaymentInfo>();
			payments.add(new PaymentInfoCash(ticket.getTotal(), ticket
					.getTotalPaid()));
			ticket.setPayments(payments);

			// Asigno los valores definitivos del ticket...
			ticket.setUser(appView.getAppUserView().getUser()
					.getUserInfo()); // El usuario que lo cobra
			ticket.setActiveCash(appView.getActiveCashIndex());
			ticket.setDate(new Date()); // Le pongo la fecha de cobro

			// Save the receipt and assign a receipt number
			try {
				dlSales.saveTicket(ticket, appView
						.getInventoryLocation());
			} catch (BasicException eData) {
				eData.printStackTrace();
			}

		} catch (TaxesException e) {
			e.printStackTrace();
		}
	}
}
