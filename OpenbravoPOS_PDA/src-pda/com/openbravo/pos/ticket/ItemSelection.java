/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */

package com.openbravo.pos.ticket;

/**
 *
 * @author axel
 */
public class ItemSelection {

    private String productId;

    private String selectedOption;

    public void setProductId(String productId) {
        this.productId = productId;
    }

    public String getProductId() {
        return productId;
    }

    public void setSelectedOption(String option) {
        this.selectedOption = option;
    }

    public String getSelectedOption() {
        return selectedOption;
    }

}
