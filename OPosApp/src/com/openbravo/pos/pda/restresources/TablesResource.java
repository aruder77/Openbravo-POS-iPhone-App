/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package com.openbravo.pos.pda.restresources;

// The Java class will be hosted at the URI path "/myresource"
import java.util.List;

import javax.ejb.Stateless;
import javax.inject.Inject;
import javax.ws.rs.GET;
import javax.ws.rs.Path;
import javax.ws.rs.Produces;
import javax.ws.rs.core.MediaType;

import com.openbravo.pos.pda.bean.TablesBean;
import com.openbravo.pos.sales.restaurant.Place;

@Stateless
@Path("/tables")
@Produces(MediaType.APPLICATION_JSON)
public class TablesResource {

	@Inject
	TablesBean bean;
	
    @GET
    public List<Place> getTables() {
    	return bean.getTables();
    }
    
    @GET
    @Path("/busyTables")
    public List<Place> getBusyTables() {
    	return bean.getBusyTables();
    }
}
