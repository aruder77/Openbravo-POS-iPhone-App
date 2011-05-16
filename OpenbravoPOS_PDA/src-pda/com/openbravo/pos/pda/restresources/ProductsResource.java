/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */

package com.openbravo.pos.pda.restresources;

import com.openbravo.pos.pda.bo.RestaurantManager;
import com.openbravo.pos.ticket.CategoryInfo;
import com.openbravo.pos.ticket.ProductInfo;
import java.util.ArrayList;
import java.util.List;
import javax.ejb.Singleton;
import javax.ws.rs.GET;
import javax.ws.rs.Path;
import javax.ws.rs.Produces;

/**
 *
 * @author axel
 */
@Singleton
@Path("/products")
public class ProductsResource {

    RestaurantManager manager = new RestaurantManager();

    @GET
    @Produces("application/json")
    public List<ProductInfo> getProducts() {
        List<ProductInfo> productList = new ArrayList<ProductInfo>();

        List<CategoryInfo> categories = manager.findAllCategories();
        for (CategoryInfo category : categories) {
            List<ProductInfo> products = manager.findProductsByCategory(category.getId());
            productList.addAll(products);
        }

        return productList;
    }
}
