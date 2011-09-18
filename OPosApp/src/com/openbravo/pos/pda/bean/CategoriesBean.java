package com.openbravo.pos.pda.bean;

import java.util.List;

import javax.annotation.PostConstruct;
import javax.ejb.Stateless;

import com.openbravo.basic.BasicException;
import com.openbravo.pos.forms.DataLogicSales;
import com.openbravo.pos.pda.app.AppViewImpl;
import com.openbravo.pos.ticket.CategoryInfo;

@Stateless
public class CategoriesBean {
	
	AppViewImpl appView;

	private DataLogicSales dls;
	
	@PostConstruct
	public void init() {
		appView = AppViewImpl.getInstance();
		dls = appView.getBean(DataLogicSales.class);
	}

	public CategoryInfo[] getCategories() {
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
