/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */

package com.openbravo.pos.pda.restresources;

import java.util.List;

import javax.ejb.Stateless;
import javax.inject.Inject;
import javax.ws.rs.GET;
import javax.ws.rs.Path;
import javax.ws.rs.Produces;

import com.openbravo.pos.pda.bean.ProductsBean;
import com.openbravo.pos.ticket.ProductInfoExt;

/**
 *
 * @author axel
 */
@Path("/products")
@Stateless
public class ProductsResource {

	@Inject
	ProductsBean bean;
	
    @GET
    @Produces("application/json")
    public List<ProductInfoExt> getProducts() {
    	return bean.getProducts();
    }
}
