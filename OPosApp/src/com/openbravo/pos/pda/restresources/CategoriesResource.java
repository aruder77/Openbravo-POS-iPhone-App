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
@Path("/categories")
public class CategoriesResource {

	@GET
	@Produces("application/json")
	public CategoryInfo[] getCategories() {
		DataLogicSales dls = new DataLogicSales();
		dls.init(AppViewImpl.getInstance());
		CategoryInfo[] categoriesArray = null;
		try {
			List<CategoryInfo> categories = null;
			categories = dls.getRootCategories();
			categoriesArray = new CategoryInfo[categories.size()];
			categories.toArray(categoriesArray);
		} catch (BasicException e) {
			e.printStackTrace();
		}
		return categoriesArray;
	}
}
