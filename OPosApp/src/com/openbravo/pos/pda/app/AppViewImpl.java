package com.openbravo.pos.pda.app;

import java.lang.reflect.Constructor;
import java.util.Date;
import java.util.HashMap;
import java.util.Locale;
import java.util.Map;
import java.util.Properties;
import java.util.UUID;
import java.util.regex.Matcher;

import com.openbravo.basic.BasicException;
import com.openbravo.data.loader.BatchSentence;
import com.openbravo.data.loader.BatchSentenceResource;
import com.openbravo.data.loader.Session;
import com.openbravo.format.Formats;
import com.openbravo.pos.forms.AppConfig;
import com.openbravo.pos.forms.AppLocal;
import com.openbravo.pos.forms.AppProperties;
import com.openbravo.pos.forms.AppUserView;
import com.openbravo.pos.forms.AppView;
import com.openbravo.pos.forms.AppViewConnection;
import com.openbravo.pos.forms.BeanFactory;
import com.openbravo.pos.forms.BeanFactoryApp;
import com.openbravo.pos.forms.BeanFactoryException;
import com.openbravo.pos.forms.BeanFactoryObj;
import com.openbravo.pos.forms.BeanFactoryScript;
import com.openbravo.pos.forms.DataLogicSystem;
import com.openbravo.pos.printer.DeviceTicket;
import com.openbravo.pos.printer.TicketParser;
import com.openbravo.pos.printer.TicketPrinterException;
import com.openbravo.pos.scale.DeviceScale;
import com.openbravo.pos.scanpal2.DeviceScanner;


public class AppViewImpl implements AppView {

	private AppProperties m_props;
	private Session session;
	private DataLogicSystem m_dlSystem;

	private Properties m_propsdb = null;
	private String m_sActiveCashIndex;
	private int m_iActiveCashSequence;
	private Date m_dActiveCashDateStart;
	private Date m_dActiveCashDateEnd;

	private String m_sInventoryLocation;

	private DeviceScale m_Scale;
	private DeviceScanner m_Scanner;
	private DeviceTicket m_TP;
	private TicketParser m_TTP;
	
	private static AppViewImpl instance;

	private Map<String, BeanFactory> m_aBeanFactories;

	private static HashMap<String, String> m_oldclasses; // This is for
															// backwards
															// compatibility
															// purposes

	static {
		initOldClasses();
	}
	
	/** Creates new form JRootApp */
	public AppViewImpl() {
        AppConfig config = new AppConfig(new String[0]);
        config.load();
        
        // set Locale.
        String slang = config.getProperty("user.language");
        String scountry = config.getProperty("user.country");
        String svariant = config.getProperty("user.variant");
        if (slang != null && !slang.equals("") && scountry != null && svariant != null) {                                        
            Locale.setDefault(new Locale(slang, scountry, svariant));
        }
        
        // Set the format patterns
        Formats.setIntegerPattern(config.getProperty("format.integer"));
        Formats.setDoublePattern(config.getProperty("format.double"));
        Formats.setCurrencyPattern(config.getProperty("format.currency"));
        Formats.setPercentPattern(config.getProperty("format.percent"));
        Formats.setDatePattern(config.getProperty("format.date"));
        Formats.setTimePattern(config.getProperty("format.time"));
        Formats.setDateTimePattern(config.getProperty("format.datetime"));               
		
		m_aBeanFactories = new HashMap<String, BeanFactory>();
		
		initApp(config);
	}
	
	public static AppViewImpl getInstance() {
		if (instance == null) {
			instance = new AppViewImpl();
		}
		return instance;
	}
	
	public boolean initApp(AppProperties props) {

		m_props = props;
		// setPreferredSize(new java.awt.Dimension(800, 600));

		// Database start
		try {
			session = AppViewConnection.createSession(m_props);
		} catch (BasicException e) {
			e.printStackTrace();
			return false;
		}

		m_dlSystem = (DataLogicSystem) getBean("com.openbravo.pos.forms.DataLogicSystem");

		// Create or upgrade the database if database version is not the
		// expected
		String sDBVersion = readDataBaseVersion();
		if (!AppLocal.APP_VERSION.equals(sDBVersion)) {

			// Create or upgrade database

			String sScript = sDBVersion == null ? m_dlSystem.getInitScript()
					+ "-create.sql" : m_dlSystem.getInitScript() + "-upgrade-"
					+ sDBVersion + ".sql";

			if (AppViewImpl.class.getResource(sScript) == null) {
				System.out.println(sDBVersion == null ? AppLocal.getIntString(
						"message.databasenotsupported", session.DB.getName()) // Create
																				// script
																				// does
																				// not
																				// exists.
																				// Database
																				// not
																				// supported
						: AppLocal.getIntString("message.noupdatescript")); // Upgrade
																			// script
																			// does
																			// not
																			// exist.
				session.close();
				return false;
			} else {
				// Create or upgrade script exists.
				try {
					BatchSentence bsentence = new BatchSentenceResource(
							session, sScript);
					bsentence.putParameter("APP_ID",
							Matcher.quoteReplacement(AppLocal.APP_ID));
					bsentence.putParameter("APP_NAME",
							Matcher.quoteReplacement(AppLocal.APP_NAME));
					bsentence.putParameter("APP_VERSION",
							Matcher.quoteReplacement(AppLocal.APP_VERSION));

					java.util.List l = bsentence.list();
				} catch (BasicException e) {
					e.printStackTrace();
					session.close();
					return false;
				}
			}
		}

		// Cargamos las propiedades de base de datos
		m_propsdb = m_dlSystem.getResourceAsProperties(m_props.getHost()
				+ "/properties");

		// creamos la caja activa si esta no existe
		try {
			String sActiveCashIndex = m_propsdb.getProperty("activecash");
			Object[] valcash = sActiveCashIndex == null ? null : m_dlSystem
					.findActiveCash(sActiveCashIndex);
			if (valcash == null || !m_props.getHost().equals(valcash[0])) {
				// no la encuentro o no es de mi host por tanto creo una...
				setActiveCash(UUID.randomUUID().toString(),
						m_dlSystem.getSequenceCash(m_props.getHost()) + 1,
						new Date(), null);

				// creamos la caja activa
				m_dlSystem.execInsertCash(new Object[] { getActiveCashIndex(),
						m_props.getHost(), getActiveCashSequence(),
						getActiveCashDateStart(), getActiveCashDateEnd() });
			} else {
				setActiveCash(sActiveCashIndex, (Integer) valcash[1],
						(Date) valcash[2], (Date) valcash[3]);
			}
		} catch (BasicException e) {
			// Casco. Sin caja no hay pos
			e.printStackTrace();
			session.close();
			return false;
		}

		// Leo la localizacion de la caja (Almacen).
		m_sInventoryLocation = m_propsdb.getProperty("location");
		if (m_sInventoryLocation == null) {
			m_sInventoryLocation = "0";
			m_propsdb.setProperty("location", m_sInventoryLocation);
			m_dlSystem.setResourceAsProperties(m_props.getHost()
					+ "/properties", m_propsdb);
		}
		
        // Inicializo la impresora...
        m_TP = new DeviceTicket(null, m_props);
        
        // Inicializamos 
        m_TTP = new TicketParser(getDeviceTicket(), m_dlSystem);
        printerStart();

		return true;
	}
	
    private void printerStart() {
        
        String sresource = m_dlSystem.getResourceAsXML("Printer.Start");
        if (sresource == null) {
            m_TP.getDeviceDisplay().writeVisor(AppLocal.APP_NAME, AppLocal.APP_VERSION);
        } else {
            try {
                m_TTP.printTicket(sresource);
            } catch (TicketPrinterException eTP) {
                m_TP.getDeviceDisplay().writeVisor(AppLocal.APP_NAME, AppLocal.APP_VERSION);
            }
        }        
    }
    


	private String readDataBaseVersion() {
		try {
			return m_dlSystem.findVersion();
		} catch (BasicException ed) {
			return null;
		}
	}

	public void tryToClose() {
		// apago el visor
		m_TP.getDeviceDisplay().clearVisor();
		// me desconecto de la base de datos.
		session.close();
	}

	// Interfaz de aplicacion
	public DeviceTicket getDeviceTicket() {
		return m_TP;
	}

	public DeviceScale getDeviceScale() {
		return m_Scale;
	}

	public DeviceScanner getDeviceScanner() {
		return m_Scanner;
	}

	public Session getSession() {
		return session;
	}

	public String getInventoryLocation() {
		return m_sInventoryLocation;
	}

	public String getActiveCashIndex() {
		return m_sActiveCashIndex;
	}

	public int getActiveCashSequence() {
		return m_iActiveCashSequence;
	}

	public Date getActiveCashDateStart() {
		return m_dActiveCashDateStart;
	}

	public Date getActiveCashDateEnd() {
		return m_dActiveCashDateEnd;
	}

	public void setActiveCash(String sIndex, int iSeq, Date dStart, Date dEnd) {
		m_sActiveCashIndex = sIndex;
		m_iActiveCashSequence = iSeq;
		m_dActiveCashDateStart = dStart;
		m_dActiveCashDateEnd = dEnd;

		m_propsdb.setProperty("activecash", m_sActiveCashIndex);
		m_dlSystem.setResourceAsProperties(m_props.getHost() + "/properties",
				m_propsdb);
	}

	public AppProperties getProperties() {
		return m_props;
	}
	
	@SuppressWarnings("unchecked")
	public <T> T getBean(Class<T> beanClass) throws BeanFactoryException {
		return (T) getBean(beanClass.getName());
	}

	public Object getBean(String beanfactory) throws BeanFactoryException {

		// For backwards compatibility
		beanfactory = mapNewClass(beanfactory);

		BeanFactory bf = m_aBeanFactories.get(beanfactory);
		if (bf == null) {

			// testing sripts
			if (beanfactory.startsWith("/")) {
				bf = new BeanFactoryScript(beanfactory);
			} else {
				// Class BeanFactory
				try {
					Class bfclass = Class.forName(beanfactory);

					if (BeanFactory.class.isAssignableFrom(bfclass)) {
						bf = (BeanFactory) bfclass.newInstance();
					} else {
						// the old construction for beans...
						Constructor constMyView = bfclass
								.getConstructor(new Class[] { AppView.class });
						Object bean = constMyView
								.newInstance(new Object[] { this });

						bf = new BeanFactoryObj(bean);
					}

				} catch (Exception e) {
					// ClassNotFoundException, InstantiationException,
					// IllegalAccessException, NoSuchMethodException,
					// InvocationTargetException
					throw new BeanFactoryException(e);
				}
			}

			// cache the factory
			m_aBeanFactories.put(beanfactory, bf);

			// Initialize if it is a BeanFactoryApp
			if (bf instanceof BeanFactoryApp) {
				((BeanFactoryApp) bf).init(this);
			}
		}
		return bf.getBean();
	}

	private static String mapNewClass(String classname) {
		String newclass = m_oldclasses.get(classname);
		return newclass == null ? classname : newclass;
	}

	@Override
	public AppUserView getAppUserView() {
		throw new UnsupportedOperationException("Operation not supported!");		
	}

	@Override
	public void waitCursorBegin() {
	}

	@Override
	public void waitCursorEnd() {
	}
	
	
    private static void initOldClasses() {
        m_oldclasses = new HashMap<String, String>();
        
        // update bean names from 2.00 to 2.20    
        m_oldclasses.put("com.openbravo.pos.reports.JReportCustomers", "/com/openbravo/reports/customers.bs");
        m_oldclasses.put("com.openbravo.pos.reports.JReportCustomersB", "/com/openbravo/reports/customersb.bs");
        m_oldclasses.put("com.openbravo.pos.reports.JReportClosedPos", "/com/openbravo/reports/closedpos.bs");
        m_oldclasses.put("com.openbravo.pos.reports.JReportClosedProducts", "/com/openbravo/reports/closedproducts.bs");
        m_oldclasses.put("com.openbravo.pos.reports.JChartSales", "/com/openbravo/reports/chartsales.bs");
        m_oldclasses.put("com.openbravo.pos.reports.JReportInventory", "/com/openbravo/reports/inventory.bs");
        m_oldclasses.put("com.openbravo.pos.reports.JReportInventory2", "/com/openbravo/reports/inventoryb.bs");
        m_oldclasses.put("com.openbravo.pos.reports.JReportInventoryBroken", "/com/openbravo/reports/inventorybroken.bs");
        m_oldclasses.put("com.openbravo.pos.reports.JReportInventoryDiff", "/com/openbravo/reports/inventorydiff.bs");
        m_oldclasses.put("com.openbravo.pos.reports.JReportPeople", "/com/openbravo/reports/people.bs");
        m_oldclasses.put("com.openbravo.pos.reports.JReportTaxes", "/com/openbravo/reports/taxes.bs");
        m_oldclasses.put("com.openbravo.pos.reports.JReportUserSales", "/com/openbravo/reports/usersales.bs");
        m_oldclasses.put("com.openbravo.pos.reports.JReportProducts", "/com/openbravo/reports/products.bs");
        m_oldclasses.put("com.openbravo.pos.reports.JReportCatalog", "/com/openbravo/reports/productscatalog.bs");
        
        // update bean names from 2.10 to 2.20
        m_oldclasses.put("com.openbravo.pos.panels.JPanelTax", "com.openbravo.pos.inventory.TaxPanel");
       
    }
}
