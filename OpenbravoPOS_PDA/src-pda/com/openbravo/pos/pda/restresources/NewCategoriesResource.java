/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */

package com.openbravo.pos.pda.restresources;

import java.util.List;

import javax.ws.rs.GET;
import javax.ws.rs.Path;
import javax.ws.rs.Produces;

import com.openbravo.basic.BasicException;
import com.openbravo.pos.forms.DataLogicSales;
import com.openbravo.pos.pda.app.AppViewImpl;
import com.openbravo.pos.ticket.CategoryInfo;

/**
 *
 * @author axel
 */
@Path("/newcategories")
@Produces("application/json")
public class NewCategoriesResource {

    @GET
    public CategoryInfo[] getCategories() {
    	DataLogicSales dls = new DataLogicSales();
    	dls.init(AppViewImpl.getInstance());
    	
    	List list = null;
    	try {
			list = dls.getCategoriesList().list();
		} catch (BasicException e) {
			e.printStackTrace();
		}
    	CategoryInfo[] cats = null;
    	if (list != null) {
    		cats = new CategoryInfo[list.size()];
    		for (int i = 0; i < list.size(); i++) {
    			cats[i] = (CategoryInfo) list.get(i);
    		}
    	}
    	
		return cats;
    }
}
