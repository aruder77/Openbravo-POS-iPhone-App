/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */

package com.openbravo.pos.pda.restresources;

import javax.ejb.Stateless;
import javax.inject.Inject;
import javax.ws.rs.GET;
import javax.ws.rs.Path;
import javax.ws.rs.Produces;

import com.openbravo.pos.pda.bean.CategoriesBean;
import com.openbravo.pos.ticket.CategoryInfo;

/**
 * 
 * @author axel
 */
@Stateless
@Path("/categories")
public class CategoriesResource {

	@Inject
	CategoriesBean bean;
	
	@GET
	@Produces("application/json")
	public CategoryInfo[] getCategories() {
		return bean.getCategories();
	}
}
