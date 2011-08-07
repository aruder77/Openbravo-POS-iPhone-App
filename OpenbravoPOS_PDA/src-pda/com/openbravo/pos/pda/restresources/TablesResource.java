/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package com.openbravo.pos.pda.restresources;

// The Java class will be hosted at the URI path "/myresource"
import java.util.List;

import javax.ws.rs.GET;
import javax.ws.rs.Path;
import javax.ws.rs.Produces;

import com.openbravo.pos.pda.bo.RestaurantManager;
import com.openbravo.pos.ticket.Place;
import com.sun.jersey.spi.resource.Singleton;

@Singleton
@Path("/tables")
@Produces("application/json")
public class TablesResource {

    RestaurantManager manager = new RestaurantManager();

    @GET
    public Place[] getTables() {
        List<Place> places = manager.findAllPlaces(manager.findAllFloors().get(0).getId());
        Place[] placesArray = new Place[places.size()];
        places.toArray(placesArray);
        return placesArray;
    }


    @GET
    @Path("/busyTables")
    public Place[] getBusyTables() {
        List<Place> places = manager.findAllBusyTable(manager.findAllFloors().get(0).getId());
        Place[] placesArray = new Place[places.size()];
        places.toArray(placesArray);
        return placesArray;
    }
}
