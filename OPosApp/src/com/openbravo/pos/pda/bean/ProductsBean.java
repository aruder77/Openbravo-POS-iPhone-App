package com.openbravo.pos.pda.bean;

import java.util.ArrayList;
import java.util.List;

import javax.annotation.PostConstruct;
import javax.ejb.Stateless;

import com.openbravo.basic.BasicException;
import com.openbravo.pos.forms.DataLogicSales;
import com.openbravo.pos.pda.app.AppViewImpl;
import com.openbravo.pos.ticket.CategoryInfo;
import com.openbravo.pos.ticket.ProductInfoExt;

@Stateless
public class ProductsBean {

	AppViewImpl appView;
	
	private DataLogicSales dls;
	
	@PostConstruct
	public void init() {
		appView = AppViewImpl.getInstance();
    	this.dls = appView.getBean(DataLogicSales.class);
	}
	
    public List<ProductInfoExt> getProducts() {
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
