
import java.io.File;
import java.net.URISyntaxException;
import java.net.URL;

import java.util.Random;


import org.junit.Test;
import org.openqa.selenium.By;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.WebDriverBackedSelenium;
import org.openqa.selenium.WebElement;
import org.openqa.selenium.interactions.Actions;
import org.openqa.selenium.remote.RemoteWebDriver;

import def.constant;
import diveboard.CommonActions;
//import diveboard.SimpleDiveActions;


public class SettingsTest  extends CommonActions{
	  String testUsername = "test-user-";
	  Random r = new Random();
	  String randomTestUsername = testUsername + Long.toString(Math.abs(r.nextLong()), 30);
	  String nickname = "New name";
	String pic_local_addr;
	String Logbook_Location;
	String nativeName;
	
	String cert1 = "Level 1";
	String cert2 = "Level 2";
	String certLocatorMain2 = "//div[@id='main_content_area']/div[2]/ul/li[2]";
	String certLocatorMain3 = "//div[@id='main_content_area']/div[2]/ul/li[3]";
	String certLocatorMain4 = "//div[@id='main_content_area']/div[2]/ul/li[4]";
	String certLocator3 = "//div[@id='certificates']/ul/li";
	String certLocator4 ="//div[@id='certificates']/ul/li[2]";
	
	
	
//	String qualificationsLocator = "css=p";
	 String path = System.getProperty("user.dir");
	
@Test
	public void testSettings() throws Exception
	{
		fb_user_id =	createTestFBUser();
		loginTempFBUser();
		changeProfile();
		checkProfileChange();
		checkOldUrl(); //negative test
		returnProfile();
		uploadPicture();
	//	loginFB();
		checkProfilePicture();
		
		changePictureToFB(); 
		checkProfilePicture();
		
		addCertifications();
		checkCertifications();
		
		changeCertifications(); 
		checkCertChange();
		delCertifications();
		checkCertDel();
		checkSettings();
		
	//	changePreferences();
	//	createSimpleNewDive();
	//	viewDiveInImperial();
	//	addDiveNotes();
		
		deleteTempFBUser(fb_user_id);
		closeBrowser();
		
	}
	
	




/*

	private void addDiveNotes() throws InterruptedException {
		System.out.println("Adding dive notes..");
		sel.open(url_new_dive);
		sel.waitForPageToLoad("300000");
		Thread.sleep(1000);
		
	
}

*/






	private void changeProfile() throws InterruptedException
	{// nativeName = sel.getLocation().substring(arg0, arg1)
	System.out.println("Logbook Profile change test..");
	openSettings();
	nativeName = sel.getValue("username");
	
	//change Logbook address
	//with uncorrect name
//	sel.type("username", "");
	type("username", "#%*@)_");
	Thread.sleep(1000);
	
	verifyTrue(sel.isVisible("username_nok"));
	verifyEquals(sel.getText("username_info"), "Username can only have characters, figures and dots in it");
	
	//* Try to save profile with empty mandatory fields(USERNAME/ Nickname/ country)
	
	click("save_form");
	waitForVisibleSel("save_nok");
	Thread.sleep(1000);	
	
	//Change USERNAME with existing name
	sel.type("username", "");
	type("username", "ksso");
//	Thread.sleep(1000);
	
	waitForVisibleSel("username_nok");
	Thread.sleep(1000);
	verifyEquals(sel.getText("username_info"), "This username is unavailable, please try another one");
	
	
	System.out.println("changing Logbook address with " + randomTestUsername);
	sel.type("username", "");
	type("username", randomTestUsername);
//	Thread.sleep(1000);
	waitForVisibleSel("username_ok");
	Thread.sleep(1000);
	//I have to check without last simbol - I think that is selenium problem		
	verifyEquals(sel.getText("username_info"), "Your url will be "+url + randomTestUsername) ;
	
	
	verifyEquals(sel.getText("//div[@id='Profile']/div[2]/div/div[2]/span[2]"), "WARNING If you change this, all links to your previous url will die.\nSo try to avoid doing that.");
	
	//change nickname
	verifyEquals(sel.getValue("nickname"),fb_user_name);
	System.out.println("changing nickname with " + nickname);
	sel.type("nickname", "");
	type("nickname", nickname);
	
	verifyEquals(sel.getText("//div[@id='Profile']/div[2]/div/div[4]/span"), "Used when referring to you * will show up in your mini-profile.");
	
	
	// change country
	System.out.println("changing country.. ");
	//sel.type("country", "");
	type("country", "Russ");
	System.out.println("waiting for country drop down...");
	waitForElement("//body/ul/li[2]/a");
	
	
	sel.mouseOver("//body/ul/li[2]/a");
	sel.click("//body/ul/li[2]/a");
	
	waitForElement("//img[@src='/img/flags/ru.gif']"); //russian flag
	

	verifyTrue(sel.isElementPresent("country_ok"));
	
	//click save
	click("save_form");
	
	verifyTrue(sel.isElementPresent("ui-dialog-title-dialog-confirm"));
	
	verifyTrue(sel.getText("css=#dialog-confirm > p").startsWith("Changing the vanity URL will permanently change the address of your logbook."));
	click("//button[@type='button']");
	
	waitForVisibleSel("id=save_ok");
	Thread.sleep(1000);
		
//	verifyEquals(sel.getText("username"), testUsername);
	
		
		
	}
	
	private void checkProfileChange() throws InterruptedException {
		sel.click("//a[@id='user_home_url']/span/img[2]");
				
		waitForElement("css=div.main_content_box.logbook_profile");
		
		//check link
		if(sel.getLocation().endsWith(randomTestUsername)) //check that link was changed
			System.out.println("Logbook address was sucessfully changed");
		else	
			System.out.println("Logbook address was NOT changed! '" + randomTestUsername +"' not equals with ending " + sel.getLocation());
		//check nick
				verifyTrue(sel.getText("css=span.header_title").startsWith(nickname));
		
		//check country
				verifyTrue(sel.isElementPresent("css=img[alt=ru]"));
		
		
	}
	
	
	private void checkOldUrl() throws InterruptedException {
		System.out.println("Check old url.. ");
		open(url+ nativeName);
		waitForElement("css=h1");
		verifyEquals(sel.getText("css=h1"), "Time to surface, diver ! It's a 404!");
		verifyTrue(sel.getText("css=p").startsWith("Apparently the page you're looking for is not available anymore"));
		verifyEquals(sel.getText("css=h2"), "Head back to the home boat where it's safe or check out some cool dives below:");
		
		
	}
	
	private void returnProfile() throws InterruptedException {
		openSettings();
				
		System.out.println("Revert profile settings.. ");
				
		sel.type("username", "");
		type("username", nativeName);
	//	sel.typeKeys("username", "");
		Thread.sleep(1000);
		verifyTrue(sel.isElementPresent("username_ok"));
		
		//I have to check without last simbol - I think that is selenium problem		
	//	verifyEquals(sel.getText("username_info"), "Your url will be http://stage.diveboard.com/"+ nativeName.substring(0, (nativeName.length()-1)) );
		
		
		verifyEquals(sel.getText("//div[@id='Profile']/div[2]/div/div[2]/span[2]"), "WARNING If you change this, all links to your previous url will die.\nSo try to avoid doing that.");
		
		//change nickname
		System.out.println("changing back nickname.. ");
		sel.type("nickname", "");
		type("nickname", fb_user_name);
		
		verifyEquals(sel.getText("//div[@id='Profile']/div[2]/div/div[4]/span"), "Used when referring to you * will show up in your mini-profile.");
		
				
		//click save
		click("save_form");
		
		verifyTrue(sel.isElementPresent("ui-dialog-title-dialog-confirm"));
		
		verifyTrue(sel.getText("css=#dialog-confirm > p").startsWith("Changing the vanity URL will permanently change the address of your logbook."));
		click("//button[@type='button']");
		
		waitForVisibleSel("id=save_ok");
		Thread.sleep(1000);
		
	}
	
	
	
	private void uploadPicture() throws InterruptedException, URISyntaxException
	{
		System.out.println("Logbook Picture upload test..");
	openSettings();
	sel.click("menu_2");
	//UPLOAD NEW PROFILE IMAGE unsupported format
	
	// unfortunately doesnt work with selenium ((
	
//	sel.type("//input[@type='file']", getProjectRoot() + "\\uploaded_files\\definetly_not_a_pict.txt");
//	Thread.sleep(2000);
//	verifyEquals("definetly_not_a_pict.txt has invalid extension. Only jpg, jpeg, png, gif, gif, bmp are allowed.", selenium.getAlert());
	
	
	//UPLOAD NEW PROFILE IMAGE < 2 Mb
//	if( constant.Local)
//	sel.type("//input[@type='file']", path + "\\uploaded_files\\test_user_img.png"); // this line caused ant error, I had to comment it
	//	sel.type("//input[@type='file']", getProjectRoot() + "\\uploaded_files\\test_user_img.png");
	//	else
		sel.type("//input[@type='file']", "C:\\test_user_img.png");
	
	waitForElement("//div[@id='picturepreview']/div/div/div[2]/div[12]");
	 
	
	/*
if( constant.Local)
	{	 driver = ( (WebDriverBackedSelenium) sel).getWrappedDriver();
	WebElement element = driver.findElement(By.xpath("//div[@id='picturepreview']/div/div/div[2]/div[12]"));
	(new Actions(driver)).dragAndDropBy(element, +250, +200);
	element = driver.findElement(By.xpath("//div[@class='jcrop-tracker']"));
	(new Actions(driver)).dragAndDropBy(element, 50, 0);
	
	}
	else
	{driverRem = (RemoteWebDriver) ( (WebDriverBackedSelenium) sel).getWrappedDriver();
		WebElement element = driverRem.findElement(By.xpath("//div[@id='picturepreview']/div/div/div[2]/div[12]"));
		(new Actions(driverRem)).dragAndDropBy(element, +250, +200);
		element = driverRem.findElement(By.xpath("//div[@class='jcrop-tracker']"));
		(new Actions(driverRem)).dragAndDropBy(element, 50, 0);
	}
		
	*/
	
	
	
	sel.dragAndDrop("//div[@id='picturepreview']/div/div/div[2]/div[12]", "230,270");
	sel.dragAndDrop("//div[@class='jcrop-tracker']","25,-20");
	click("save_form");
	
	waitForVisibleSel("id=save_ok");
	Thread.sleep(1000);
	pic_local_addr = sel.getAttribute("//img[@id='preview']@src");
	}
	
	  
	
	public String getProjectRoot() throws URISyntaxException {
	      URL u = this.getClass().getProtectionDomain().getCodeSource()
			                .getLocation();
		        File f = new File(u.toURI());
			        return f.getParent();
			    }
	

	
	

	private void checkProfilePicture() throws InterruptedException {
		sel.click("//a[@id='user_home_url']/span/img[2]");
		
		waitForElement("css=div.main_content_box.logbook_profile");
		
		verifyTrue(sel.isElementPresent("//div[@id='sidebar']/div/div/div/img[contains(@src, '"+pic_local_addr+"')]"));
		
		
	
}
	
	
	
	private void changePictureToFB() throws InterruptedException {
		System.out.println("Switch between FB pic and uploaded pic");
		openSettings();
		sel.click("menu_2");
		sel.click("use_facebook");
		pic_local_addr = sel.getAttribute("//img[@id='preview']@src");
		if(pic_local_addr.startsWith("http://graph.facebook.com/v2.0/"))
			System.out.println("Facebook Picture selected");
			
		sel.click("save_form");
		waitForVisible("id=save_ok");
	}

	
	
	private void addCertifications () throws InterruptedException
	{
		System.out.println("Certifications add..");
	openSettings();
	sel.click("menu_3");
	waitForElement("qualif_title");
	
	
	
	sel.type("qualif_title", cert1);
	sel.select("qualif_orga", "label=PADI");
	sel.type("qualif_date_picker", "1999-12-12");
	sel.click("add_qualification");
	sel.type("qualif_title", cert2);
	sel.select("qualif_orga", "label=CMAS");
	sel.type("qualif_date_picker", "1989-12-12");
	sel.click("add_qualification");
	verifyEquals(cert1, sel.getText("//ul[@id='sortable2']/li[1]/div[2]"));
	verifyEquals("PADI", sel.getText("//ul[@id='sortable2']/li[1]/div[1]"));
	verifyEquals("1999-12-12", sel.getText("//ul[@id='sortable2']/li[1]/div[3]"));
	verifyEquals("CMAS", sel.getText("//ul[@id='sortable2']/li[2]/div[1]"));
	verifyEquals(cert2, sel.getText("//ul[@id='sortable2']/li[2]/div[2]"));
	verifyEquals("1989-12-12", sel.getText("//ul[@id='sortable2']/li[2]/div[3]"));
//	sel.dragAndDrop("//ul[@id='sortable2']/li", "10,-70");  //moving cert1 to Main qualifications
	sel.dragAndDrop("//ul[@id='sortable2']/li", "10,-60"); 
//	sel.dragAndDrop("//ul[@id='sortable2']/li", "10,-40");
//	sel.dragAndDrop("//ul[@id='sortable2']/li", "10,-10");
	sel.click("save_form");
	waitForVisible("id=save_ok");

	
		
	}
	
	
	private void checkCertifications() throws Exception
	{System.out.println("Checking certifications..");
		sel.open("/");
		
		waitForElement("css=div.main_content_box.logbook_profile");
		
		 Logbook_Location = sel.getLocation();
		 
	//	verifyEquals("PADI Level X", sel.getText(certLocatorMain1));
		
		verifyEquals("PADI "+cert1+" (Dec 1999)", sel.getText(certLocatorMain3));
		verifyEquals("CMAS "+cert2+" (Dec 1989)", sel.getText(certLocatorMain4));
		verifyEquals("PADI "+cert1+" (Dec 1999)", sel.getText(certLocator3));
		verifyEquals("CMAS "+cert2+" (Dec 1989)", sel.getText(certLocator4));
		
		
		
		logout();
				
		
//		verifyEquals("Connect to facebook, to share your dives and photos with friends.", sel.getText("//div[@id='slide_one']/p"));
		
		sel.open(Logbook_Location);
		waitForElement("css=div.main_content_box.logbook_profile");
	//	verifyEquals("PADI Level X", sel.getText(certificationLocator));
		verifyEquals("PADI "+cert1+" (Dec 1999)", sel.getText(certLocatorMain2));
		verifyEquals("CMAS "+cert2+" (Dec 1989)", sel.getText(certLocatorMain3));
		loginFB();

		
	}
	
	private void changeCertifications() throws InterruptedException
	{	System.out.println("Changing Certifications..");
		openSettings();
		sel.click("menu_3");
		//cert1
		//cert2
		//change places Main qualifications
		sel.dragAndDrop("//ul[@id='sortable2']/li/div", "0,-300");
		sel.dragAndDrop("css=div.settings_cert_box_one","10,70"); 
		//cert2
		//cert1
		
		sel.click("save_form");
		waitForVisible("id=save_ok");
	}
	

	private void checkCertChange() throws Exception {
		System.out.println("Checking Certifications..");
		sel.open("/");
		waitForElement("css=div.main_content_box.logbook_profile");
	//	verifyEquals("CMAS Big Diver", sel.getText(certificationLocator));
	//	verifyEquals("Qualifications: PADI Level X", sel.getText(qualificationsLocator));
		verifyEquals("PADI "+cert1+" (Dec 1999)", sel.getText(certLocatorMain3));
		verifyEquals("CMAS "+cert2+" (Dec 1989)", sel.getText(certLocatorMain4));
		verifyEquals("PADI "+cert1+" (Dec 1999)", sel.getText(certLocator3));
		verifyEquals("CMAS "+cert2+" (Dec 1989)", sel.getText(certLocator4));
		
		logout();
		
	//	verifyEquals("Connect to facebook, to share your dives and photos with friends.", sel.getText("//div[@id='slide_one']/p"));
	
		sel.open(Logbook_Location);
		waitForElement("css=div.main_content_box.logbook_profile");
	//	verifyEquals("CMAS Big Diver", sel.getText(certificationLocator));
	//	verifyEquals("Qualifications: PADI Level X", sel.getText(qualificationsLocator));
		verifyEquals("PADI "+cert1+" (Dec 1999)", sel.getText(certLocatorMain2));
		verifyEquals("CMAS "+cert2+" (Dec 1989)", sel.getText(certLocatorMain3));
		
		verifyFalse(sel.isElementPresent(certLocator3));
		verifyFalse(sel.isElementPresent(certLocator4));
		
		loginFB();
	
		
	
}
	
		private void delCertifications() throws InterruptedException
		{System.out.println("Removing Certifications..");
			openSettings();
			sel.click("menu_3");
			sel.click("link=x");
			sel.click("link=x");
			sel.click("save_form");
			waitForVisible("id=save_ok");
			}

		private void checkCertDel() throws InterruptedException {
			System.out.println("Checking No Certifications..");
			sel.open("/");
			waitForElement("css=div.main_content_box.logbook_profile");
			verifyEquals("", sel.getText(certLocatorMain3));
			
			verifyFalse(sel.isElementPresent(certLocatorMain3));
			verifyFalse(sel.isElementPresent(certLocatorMain4));
			verifyFalse(sel.isElementPresent(certLocator3));
			verifyFalse(sel.isElementPresent(certLocator4));
			
	}
		
		


		private void checkSettings() throws InterruptedException {
			System.out.println("Verify settings->notifications..");
			openSettings();
			sel.click("menu_4");
			
			verifyEquals("Publish your dives when complete :", sel.getText("//div[@id='Preferences']/div[2]/div/div[2]/label"));
			verifyEquals("Enable post to FB wall by default :", sel.getText("//div[@id='Preferences']/div[2]/div/div[2]/label[2]"));
			
			sel.click("id=pref_auto_public");
			sel.click("id=pref_auto_fb_share");
			
			verifyEquals("NEWSLETTER - NOTIFICATIONS", sel.getText("css=div.settings_newsletter_box > span.third_lvl_header"));
		
			verifyTrue(sel.isElementPresent("css=span.newsletter_label"));
		//	verifyTrue(sel.isElementPresent("id=pref_email"));  //removed
			
			verifyEquals("Notifications:", sel.getText("//div[@id='Preferences']/div[2]/div/div[7]/div/label"));
			
			
			verifyEquals("exact:News:", sel.getText("//div[@id='Preferences']/div[2]/div/div[7]/div[2]/label"));
			
			verifyEquals("Keep me in the loop for more great scuba news.", sel.getText("//div[@id='Preferences']/div[2]/div/div[7]/label[2]"));
			
			verifyEquals("Notify me when someone likes or comments my dives.", sel.getText("css=div.settings_newsletter_box > label"));
			
			sel.click("id=comments_notifs");
			sel.click("id=pref_opt_in");
			sel.type("id=pref_email", "");
			
			sel.click("id=save_form");
			waitForVisible("id=save_ok");
	}

/*
		private void changePreferences() throws InterruptedException {
			System.out.println("Changing Preferences..");
			openSettings();
			sel.click("menu_4"); // open Preferences
			sel.uncheck("id=pref_auto_public");  // uncheck Publish your dives when complete 
			sel.check("id=pref_auto_fb_share"); //check Enable post to FB wall by default
			sel.click("link=Advanced");
			sel.uncheck("id=pref_share_details_notes");  //Share your dive notes uncheck
			sel.click("//input[@name='sci_privacy' and @value='3']"); //I don't want to share my data 
			sel.select("pref_units", "value=2"); //Imperial
			sel.uncheck("id=comments_notifs"); //Notify me when someone likes or comments my dives.
			sel.uncheck("id=pref_opt_in"); // Keep me in the loop for more great scuba news.
			sel.click("save_form");
			waitForVisible("save_ok");
			
			
		}
*/
		
		
		
	}
	
	
	
	
	

