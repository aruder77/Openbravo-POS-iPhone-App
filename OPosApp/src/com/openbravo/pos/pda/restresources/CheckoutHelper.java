package com.openbravo.pos.pda.restresources;

import java.io.File;
import java.math.BigDecimal;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;
import java.util.Properties;

import org.apache.commons.beanutils.PropertyUtils;

import com.openbravo.basic.BasicException;
import com.openbravo.data.loader.Session;
import com.openbravo.pos.forms.AppConfig;
import com.openbravo.pos.forms.DataLogicSales;
import com.openbravo.pos.forms.DataLogicSystem;
import com.openbravo.pos.payment.PaymentInfo;
import com.openbravo.pos.payment.PaymentInfoCash;
import com.openbravo.pos.pda.app.AppViewImpl;
import com.openbravo.pos.ticket.TicketInfo;
import com.openbravo.pos.ticket.UserInfo;

public class CheckoutHelper {

	private String getActiveCash() {
		// Cargamos las propiedades de base de datos
		Properties m_propsdb = dataLogicSystem
				.getResourceAsProperties(properties.getHost() + "/properties");

		String sActiveCashIndex = m_propsdb.getProperty("activecash");
		if (sActiveCashIndex == null) {
			throw new RuntimeException("No active cash!!!");
		}

		return sActiveCashIndex;
	}

	public void checkout(TicketInfo ticket, String place) throws BasicException {
		RestaurantManager manager = new RestaurantManager();
		manager.refreshTax(ticket);

		UserInfo user = manager.findUser("Inge Wiedmann", "");
		ticket.setUser(user);
		ticket.setActiveCash(getActiveCash());
		List<PaymentInfo> payments = new ArrayList<PaymentInfo>();
		BigDecimal total = manager.getTotalOfaTicket(place);
		double totalValue = total.doubleValue();
		payments.add(new PaymentInfoCash(totalValue, 10.0));
		ticket.setPayments(payments);
		ticket.setDate(new Date());
		DataLogicSales dls = AppViewImpl.getBean(DataLogicSales.class);
		dls.saveTicket(ticket, "0");
		dls.deleteTicket(ticket, place);
	}
}
