/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package com.openbravo.pos.pda.restresources;

// The Java class will be hosted at the URI path "/myresource"
import com.openbravo.pos.pda.bo.RestaurantManager;
import com.openbravo.pos.ticket.Place;
import com.sun.jersey.spi.resource.Singleton;
import java.util.List;
import javax.ws.rs.GET;
import javax.ws.rs.Path;
import javax.ws.rs.Produces;

@Singleton
@Path("/tables")
public class TablesResource {

    RestaurantManager manager = new RestaurantManager();

    @GET
    @Produces("application/json")
    public Place[] getTables() {
        List<Place> places = manager.findAllPlaces(manager.findAllFloors().get(0).getId());
        Place[] placesArray = new Place[places.size()];
        places.toArray(placesArray);
        return placesArray;
    }


    @GET
    @Path("/busyTables")
    @Produces("application/json")
    public Place[] getBusyTables() {
        List<Place> places = manager.findAllBusyTable(manager.findAllFloors().get(0).getId());
        Place[] placesArray = new Place[places.size()];
        places.toArray(placesArray);
        return placesArray;
    }

}
