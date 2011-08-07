/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */

package com.openbravo.pos.pda.restresources;

import java.util.ArrayList;
import java.util.List;

import javax.ws.rs.GET;
import javax.ws.rs.Path;
import javax.ws.rs.Produces;

import com.openbravo.basic.BasicException;
import com.openbravo.pos.forms.DataLogicSales;
import com.openbravo.pos.pda.app.AppViewImpl;
import com.openbravo.pos.ticket.CategoryInfo;
import com.openbravo.pos.ticket.ProductInfoExt;

/**
 *
 * @author axel
 */
@Path("/products")
public class ProductsResource {

    @GET
    @Produces("application/json")
    public List<ProductInfoExt> getProducts() {
    	DataLogicSales dls = new DataLogicSales();
    	dls.init(AppViewImpl.getInstance());
    	
        List<ProductInfoExt> productList = new ArrayList<ProductInfoExt>();

        List<CategoryInfo> categories;
		try {
			categories = dls.getRootCategories();
	        for (CategoryInfo category : categories) {
	            List<ProductInfoExt> products = dls.getProductCatalog(category.getID());
	            productList.addAll(products);
	        }

		} catch (BasicException e) {
			e.printStackTrace();
		}
        return productList;
    }
}
