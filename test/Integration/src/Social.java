//import java.awt.event.KeyEvent;

import org.junit.Test;

import diveboard.SimpleDiveActions;
public class Social extends SimpleDiveActions {

	@Test
	public void testSocialActions() throws Exception {
		
		fb_user_id =createTestFBUser();
		
		register();
		createSimpleNewDive();
		diveShare();
	//	diveLikeinHeader();  webdriver doesnt see 'Like' button :(
		googlePlusOne();
	//	diveLikeInComments();		 webdriver doesnt see Fb frame :(
		sel.open("/ksso");
		sel.waitForPageToLoad("300000");
//		addAsBuddy(); skipped cause unable to add buddy by temp FB user
		likeDiveboard(); 
		diveShare();
	//	diveLikeinHeader(); there is a bug ¹ 108 in profile - should be fixed first
		googlePlusOne();
		sel.close();
	}

	
	private void likeDiveboard() throws InterruptedException {
		
		verifyTrue(sel.isElementPresent("css=div.connect_top.clearfix"));
		
		verifyTrue(sel.isElementPresent("//span[text()='Diveboard']"));
		
		verifyTrue(sel.isElementPresent("//div[@class='connect_top clearfix']"));
		
		verifyTrue(sel.isElementPresent("//span[@class='connect_widget_not_connected_text']"));
		
		verifyTrue(sel.isElementPresent("css=span.liketext"));
		
	// webdriver doesnt see it :'(
		/*
		verifyEquals("Diveboard", sel.getText("css=span.name"));
		
		System.out.println("Diveboard was liked " + sel.getText("//span[@class='connect_widget_not_connected_text']") + " times, adding +1");
		
		sel.click("css=span.liketext");
		waitForElement("css=div.connect_confirmation_cell.connect_confirmation_cell_no_like > a");
	*/
	
	}

	private void diveLikeInComments() throws InterruptedException {
		
		System.out.println("Liking this dive " + sel.getLocation());
		verifyTrue(sel.getText("css=span.commentas_inner").startsWith("Posting as "+Full_fb_user_name+" (Not you?)"));
		verifyEquals("Be the first of your friends to like this.", sel.getText("//div[@id='LikePluginPagelet']/div/table/tbody/tr/td[3]/div/div/span[3]/span[2]"));
	
		
	//	sel.selectFrame("//div[@class='double_box']//span/iframe[@class='fb_ltr']");
		
		
		/* Could not add comment by selenium in frame!!!!!!
		
		
	//	sel.selectFrame("//div[@class='double_box']//span/iframe[@class='fb_ltr']");
		
		sel.focus("//div[@class='innerWrap']");
	//	sel.type("name=text_text", "");
	//	sel.typeKeys("name=text_text", "Dive comment");
	//	sel.mouseDownAt("//div[@class='innerWrap']", "10,-10");
	//	sel.typeKeys("//div[@class='innerWrap']", "Dive comment");
		sel.keyPressNative(Integer.toString(KeyEvent.VK_1));
		sel.keyPressNative(Integer.toString(KeyEvent.VK_2));
		sel.click("//label[@class='fbCommentButton uiButton uiButtonConfirm']/input");
		waitForElement("css=div.postText");
		verifyEquals("Dive comment", sel.getText("css=div.postText"));
		
		//delete comment
		
		sel.click("//div/div/div/label/input");
		waitForElement("css=div.dialog_body");
		sel.click("name=delete");
		waitForNotVisible("css=div.dialog_body");
		verifyFalse(sel.isElementPresent("css=div.postText"));
		
		*/
		
		
		//like
		
	//	sel.selectFrame("//div[@class='double_box']//span/iframe[@class='fb_ltr']");
		//	sel.click("//div[@id='LikePluginPagelet']/div/table/tbody/tr/td/div/div/a/div");	
		
		
		sel.click("//html/body/div[2]/div/table/tbody/tr/td/div/div/a/div");	//click like in comments frame
		
		for (int second = 0;; second++) {
			if (second >= 15) 
				{System.out.println("'like' was not pressed, trying 1 more time");
					sel.click("//html/body/div[2]/div/table/tbody/tr/td/div/div/a/div");
				}
			try { if (sel.isVisible("//div[@id='LikePluginPagelet']/div/table/tbody/tr/td[3]/div/div/span[3]/span")) break; } 
			catch (Exception e) {}
			Thread.sleep(1000);
			}	
		
		
		waitForVisible("//div[@id='LikePluginPagelet']/div/table/tbody/tr/td[3]/div/div/span[3]/span");
		
		verifyEquals(sel.getText("//div[@id='LikePluginPagelet']/div/table/tbody/tr/td[3]/div/div/span[3]/span"),
				Full_fb_user_name+" likes this.");
		
		
		//not visible 'Be the first of your friends to like this.'
		verifyFalse(sel.isVisible("//div[@id='LikePluginPagelet']/div/table/tbody/tr/td[3]/div/div/span[3]/span[2]"));
		
		
		
	}

	private void googlePlusOne() {
		verifyTrue(sel.isElementPresent("//div[@id='plusone']/table/tbody/tr/td/div/a"));
		verifyTrue(sel.isElementPresent("id=aggregateCount"));
		//verifyEquals("0", sel.getText("id=aggregateCount"));
	
		//webdriver doesnt see it :(
	//	verifyEquals("0", sel.getText("//div[@id='aggregateBubble']/div"));
		
	}

	
	
	private void diveLikeinHeader() throws InterruptedException {
		System.out.println("Checking likes in header");
		verifyTrue(sel.isElementPresent("css=div.thumbs_up_icon"));
//		verifyEquals("0", sel.getText("css=span.connect_widget_not_connected_text"));
	
		//click like
	
		//	sel.click("//div[@class='connect_widget_connect_button']/a/span");
		
		verifyTrue(sel.isElementPresent("//div[@id='LikePluginPagelet']/div/div/div[2]/a/div"));	
	sel.click("//div[@id='LikePluginPagelet']/div/div/div[2]/a/div");	
	
	//	sel.mouseDown("//div[contains(@id,'connect_widget')]/div/div[2]/a/span");
		
		waitForVisible("css=div.connect_comment_widget_text");
		verifyEquals("You like this.Unlike", sel.getText("css=div.connect_comment_widget_text"));
		sel.type("css=textarea.connect_comment_widget_full_input_textarea.inputtext", "Nice dive!");
		sel.click("//label/input[@value='Post to Facebook']");
		// +1 like check
		if(waitAndVerifyVisible("//div[@class='connect_widget_number_cloud']/table/tbody/tr/td[2]/span/span"))
			verifyEquals("1", sel.getText("//div[@class='connect_widget_number_cloud']/table/tbody/tr/td[2]/span/span"));
		// unlike
		sel.click("//div[@class='connect_widget_connect_button']/a/div");
		if(waitAndVerifyVisible("//div[@class='connect_widget_number_cloud']/table/tbody/tr/td[2]/span/span[2]"))
			verifyEquals("0", sel.getText("//div[@class='connect_widget_number_cloud']/table/tbody/tr/td[2]/span/span[2]"));
		waitAndVerifyVisible("//div[@class='connect_widget_number_cloud']/table/tbody/tr/td[2]/span/span[2]");
		sel.click("css=span.liketext");
		waitAndVerify("css=div.tombstone_cross.");
	

		
	}

	private void diveShare() throws InterruptedException {
		System.out.println("Checking share links for " + sel.getLocation());
		sel.click("//a[@id='share_this_link']/img"); //click share
		waitForVisible("id=diveboard_share_menu");
		verifyEquals("SHARE ON SOCIAL NETWORKS", sel.getText("css=li.even"));
	//	verifyTrue(sel.isVisible("id=diveboard_share_menu"));
		verifyTrue(sel.isVisible("css=li.dimension > a > img"));
		verifyTrue(sel.isVisible("//div[@id='diveboard_share_menu']"));

		verifyTrue(sel.isElementPresent("link=Tweet"));
	
		verifyEquals("GRAB THE LINK", sel.getText("css=li.odd"));
		sel.click("css=li.odd");
		waitForVisible("css=span.diveboard_share_menu_40");
		verifyEquals("Long link:", sel.getText("css=span.diveboard_share_menu_40"));
		verifyEquals(sel.getLocation(), sel.getValue("css=input.share_link_input"));
		verifyEquals("Short link:", sel.getText("//div[@id='diveboard_share_menu']/div/ul/li[4]/span[2]"));
		verifyTrue(sel.getValue("//div[@id='diveboard_share_menu']/div/ul/li[4]/input[2]").startsWith("http://stage.scu.bz/"));
		sel.click("css=li.even");
		waitForVisible("css=li.dimension > a > img");
		verifyTrue(sel.isElementPresent("id=btn"));
				
		// could not swith between windows! ERROR: Window does not exist. If this looks like a Selenium bug
		/*
		String[] winIDs = sel.getAllWindowNames();
		int origCount = winIDs.length; // Scan original number of available windows

		
		sel.click("css=li.dimension > a > img");
		
				
		for( int i = 0 ; i < minute ; i++ ){
			winIDs = sel.getAllWindowNames();
			if( winIDs.length > origCount ){
		        break; // If the number of open windows becomes greater than before we exit the loop
		                         }
			Thread.sleep(1000);            
		          }
		
		
		        
		  //focus FB allow popup
		  //   sel.selectWindow("name="+winIDs[winIDs.length - 1] );
		     Thread.sleep(1000);
		                        
		     waitForElement("name=share");                
		     sel.click("name=share");
		   
		     //return to main window            
		     sel.selectWindow("null");                      
		  
		*/     
		     
		     
		sel.click("id=share_close");
		sel.mouseDown("id=share_this_link");
		verifyTrue(sel.isElementPresent("css=a[name=\"modal\"] > img.tooltiped-js"));
		verifyTrue(sel.isElementPresent("//img[@alt='Public']"));

	}
	
}
