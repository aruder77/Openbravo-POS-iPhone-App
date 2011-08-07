/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */

package com.openbravo.pos.pda.restresources;

import java.util.ArrayList;
import java.util.List;
import javax.xml.bind.annotation.XmlRootElement;

/**
 *
 * @author axel
 */
@XmlRootElement
public class TicketAddition {

    private String ticketId;

    private List<String> productIds;

    public TicketAddition() {
        productIds = new ArrayList<String>();
    }

    public void setTicketId(String id) {
        this.ticketId = id;
    }

    public String getTicketId() {
        return this.ticketId;
    }

    public void setProductIds(List<String> selections) {
        this.productIds = selections;
    }

    public List<String> getProductIds() {
        return this.productIds;
    }

    public void add(String selection) {
        this.productIds.add(selection);
    }
}
