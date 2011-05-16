/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package com.openbravo.pos.pda.restresources;

import com.openbravo.pos.printer.TicketParser;
import com.openbravo.pos.printer.DeviceTicket;
import com.openbravo.pos.forms.DataLogicSystem;
import com.openbravo.pos.forms.AppConfig;
import com.openbravo.data.loader.Session;
import com.openbravo.pos.pda.util.PropertyUtils;
import com.openbravo.pos.printer.TicketPrinterException;
import com.openbravo.pos.scripting.ScriptEngine;
import com.openbravo.pos.scripting.ScriptException;
import com.openbravo.pos.scripting.ScriptFactory;
import com.openbravo.pos.ticket.TicketInfo;
import com.openbravo.pos.ticket.TicketLineInfo;
import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;
import java.sql.SQLException;
import java.util.List;
import java.util.Properties;

/**
 *
 * @author awolf
 */
public class TestPrint {

    private final String APP_ID = "openbravopos";
    private PropertyUtils properties;
    
    private DataLogicSystem dls = null;
    private DeviceTicket dt = null;
    private AppConfig ap = null;
    
    public TestPrint() {
        properties = new PropertyUtils();

        ap = new AppConfig(getDefaultConfig());
        ap.load();

        Session s = null;
        try {

            s = new Session(properties.getUrl(), properties.getDBUser(), properties.getDBPassword());
        } catch (SQLException ex) {
            ex.printStackTrace();
        }
        dls = new DataLogicSystem();
        dls.init(s);
    }

    private static String readFileAsString(String filePath)
            throws java.io.IOException {
        StringBuffer fileData = new StringBuffer(1000);
        BufferedReader reader = new BufferedReader(
                new FileReader(filePath));
        char[] buf = new char[1024];
        int numRead = 0;
        while ((numRead = reader.read(buf)) != -1) {
            String readData = String.valueOf(buf, 0, numRead);
            fileData.append(readData);
            buf = new char[1024];
        }
        reader.close();
        return fileData.toString();
    }

    private File getDefaultConfig() {
        return new File(new File(System.getProperty("user.home")), APP_ID + ".properties");
    }

    public boolean PrintPDATicket(String place, TicketInfo ticket, String printerName) {
        dt = new DeviceTicket(null, ap);

        TicketParser tp = new TicketParser(dt, dls);
        try {

            String xml = getTicketXML(dls, place, ticket, printerName);
            if (xml != null) {
                tp.printTicket(xml);
            } else {
                return false;
            }
        } catch (TicketPrinterException ex) {
            ex.printStackTrace();
            return false;
        }

        return true;

    }

    private String getTicketXML(DataLogicSystem d, String ticketext, TicketInfo ticket, String printerName) {
        String sresource = d.getResourceAsXML("Printer." + printerName);
        if (sresource == null) {
        } else {
            try {
                List<TicketLineInfo> lines = ticket.getLines();
                for (TicketLineInfo line : lines) {
                    if (line.getProduct() != null) {
                        Properties p = line.getProduct().getAttributes();
                        for (Object key : p.keySet()) {
                            if (key instanceof String) {
                                String keyStr = (String) key;
                                System.out.println("Key: " + keyStr + " value: " + p.getProperty(keyStr));
                            }
                        }
                    }
                }

                ScriptEngine script = ScriptFactory.getScriptEngine(ScriptFactory.VELOCITY);
                //script.put("taxes", taxcollection);
                //script.put("taxeslogic", taxeslogic);
                script.put("ticket", ticket);
                script.put("place", ticketext);
                return script.eval(sresource).toString();
            } catch (ScriptException e) {
            }

        }
        return null;
    }
}
