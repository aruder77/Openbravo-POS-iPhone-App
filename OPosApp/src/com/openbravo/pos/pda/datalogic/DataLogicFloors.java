package com.openbravo.pos.pda.datalogic;

import java.util.ArrayList;
import java.util.List;

import com.openbravo.basic.BasicException;
import com.openbravo.data.loader.PreparedSentence;
import com.openbravo.data.loader.SentenceList;
import com.openbravo.data.loader.SerializerReadClass;
import com.openbravo.data.loader.SerializerWriteString;
import com.openbravo.data.loader.Session;
import com.openbravo.data.loader.StaticSentence;
import com.openbravo.pos.forms.BeanFactoryDataSingle;
import com.openbravo.pos.sales.restaurant.Floor;
import com.openbravo.pos.sales.restaurant.Place;

public class DataLogicFloors extends BeanFactoryDataSingle {

	private Session session;

	public DataLogicFloors() {
	}
	
	public void init(Session s) {
		session = s;
	}
	
	@SuppressWarnings("unchecked")
	public List<Floor> getFloors() {
		List<Floor> floors = null;
        try {
            SentenceList sent = new StaticSentence(
                    session, 
                    "SELECT ID, NAME, IMAGE FROM FLOORS ORDER BY NAME", 
                    null, 
                    new SerializerReadClass(Floor.class));
            floors = sent.list();
        } catch (BasicException eD) {
            floors = new ArrayList<Floor>();
        }
        return floors;
	}
	
	@SuppressWarnings("unchecked")
	public List<Place> getPlaces() {
		List<Place> places = null;
        try {
            SentenceList sent = new StaticSentence(
                    session, 
                    "SELECT ID, NAME, X, Y, FLOOR FROM PLACES ORDER BY FLOOR", 
                    null, 
                    new SerializerReadClass(Place.class));
            places = sent.list();
        } catch (BasicException eD) {
        	places = new ArrayList<Place>();
        } 
        return places;
	}
	
	@SuppressWarnings("unchecked")
	public List<Place> getPlaceByFloor(String id) {
		List<Place> places = null;
        try {
			places = new PreparedSentence(session
			        , "SELECT ID, NAME, X, Y, FLOOR FROM PLACES WHERE FLOOR = ?"
			        , SerializerWriteString.INSTANCE
			        , new SerializerReadClass(Place.class)).list(id);
		} catch (BasicException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
        return places;
	}
}
