package com.openbravo.pos.pda.bean;

import java.util.ArrayList;
import java.util.List;

import javax.annotation.PostConstruct;
import javax.ejb.Stateless;

import com.openbravo.pos.pda.app.AppViewImpl;
import com.openbravo.pos.pda.datalogic.DataLogicFloors;
import com.openbravo.pos.sales.restaurant.Floor;
import com.openbravo.pos.sales.restaurant.Place;

@Stateless
public class TablesBean {

	AppViewImpl appView;
	
	DataLogicFloors dlf;
	
	@PostConstruct
	public void init() {
		appView = AppViewImpl.getInstance();
		this.dlf = appView.getBean(DataLogicFloors.class);
	}
	
    public List<Place> getTables() {
    	Floor floor = dlf.getFloors().get(0);
    	List<Place> places = dlf.getPlaceByFloor(floor.getID());
		return places;
    }
    
    public List<Place> getBusyTables() {
    	List<Place> places = getTables();
    	List<Place> busyPlaces = new ArrayList<Place>();
    	for (Place place : places) {
    		if (place.hasPeople()) {
    			busyPlaces.add(place);
    		}
    	}
    	return busyPlaces;
    }

}
