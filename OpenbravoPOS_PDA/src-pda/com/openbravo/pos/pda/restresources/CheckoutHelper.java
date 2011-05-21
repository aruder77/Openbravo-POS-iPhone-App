package com.openbravo.pos.pda.restresources;

import java.io.File;
import java.math.BigDecimal;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;
import java.util.Properties;
import java.util.UUID;

import com.openbravo.basic.BasicException;
import com.openbravo.data.gui.MessageInf;
import com.openbravo.data.loader.Session;
import com.openbravo.pos.forms.AppConfig;
import com.openbravo.pos.forms.AppLocal;
import com.openbravo.pos.forms.DataLogicSystem;
import com.openbravo.pos.pda.bo.DataLogicSales;
import com.openbravo.pos.pda.bo.RestaurantManager;
import com.openbravo.pos.pda.util.PropertyUtils;
import com.openbravo.pos.ticket.PaymentInfo;
import com.openbravo.pos.ticket.PaymentInfoCash;
import com.openbravo.pos.ticket.TicketInfo;
import com.openbravo.pos.ticket.UserInfo;

public class CheckoutHelper {

	private final String APP_ID = "openbravopos";
	private DataLogicSales dls;
	private DataLogicSystem dataLogicSystem;
	private AppConfig ap;
	private PropertyUtils properties;

	public CheckoutHelper() {
		properties = new PropertyUtils();

		ap = new AppConfig(getDefaultConfig());
		ap.load();

		Session s = null;
		try {
			s = new Session(properties.getUrl(), properties.getDBUser(),
					properties.getDBPassword());
		} catch (SQLException ex) {
			ex.printStackTrace();
		}
		dls = new DataLogicSales();
		dls.init(s);

		dataLogicSystem = new DataLogicSystem();
		dataLogicSystem.init(s);
	}

	private File getDefaultConfig() {
		return new File(new File(System.getProperty("user.home")), APP_ID
				+ ".properties");
	}

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
		dls.saveTicket(ticket, "0");
		manager.deleteTicket(place);
	}
}
