/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package com.openbravo.pos.pda.restresources;

// The Java class will be hosted at the URI path "/myresource"
import java.util.ArrayList;
import java.util.List;

import javax.ws.rs.GET;
import javax.ws.rs.Path;
import javax.ws.rs.Produces;

import com.openbravo.pos.pda.app.AppViewImpl;
import com.openbravo.pos.pda.datalogic.DataLogicFloors;
import com.openbravo.pos.sales.restaurant.Floor;
import com.openbravo.pos.sales.restaurant.Place;
import com.sun.jersey.spi.resource.Singleton;

@Singleton
@Path("/tables")
@Produces("application/json")
public class TablesResource {

    @GET
    public Place[] getTables() {
    	DataLogicFloors dlf = new DataLogicFloors();
    	dlf.init(AppViewImpl.getInstance());
    	
    	Floor floor = dlf.getFloors().get(0);
    	List<Place> places = dlf.getPlaceByFloor(floor.getID());
		return places.toArray(new Place[places.size()]);
    }
    
    @GET
    @Path("/busyTables")
    public Place[] getBusyTables() {
    	Place[] places = getTables();
    	List<Place> busyPlaces = new ArrayList<Place>();
    	for (Place place : places) {
    		if (place.hasPeople()) {
    			busyPlaces.add(place);
    		}
    	}
    	return busyPlaces.toArray(new Place[busyPlaces.size()]);
    }
}
