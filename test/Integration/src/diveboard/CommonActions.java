package diveboard;

import java.io.File;
import java.io.IOException;
import java.util.Random;



import org.junit.runner.RunWith;




import AfterFailures.*;



/**
* Common actions for test cases
* 
* Created by Uaka Ama.
* Date: 10.06.2011
*/

@RunWith(RCRunner.class)

	public class CommonActions  extends WebdriverMethods {
			
		public static String fb_user_id;
		public static String user_url;
	//	public static String fb_user_login_url ;
	//	public static String fb_user_password ;
		public static String fb_user_name;
		public static String Full_fb_user_name;

	
		public	String testUsername = "test_user";
		public	  Random r = new Random();
		public	  String randomTestUsername = testUsername + Long.toString(Math.abs(r.nextLong()), 30);
		public	  String email = randomTestUsername +"@diveboard.com";
		public	  String username = "test-user";
		public	  String userPass = "12345";
		public	  String userPassNew = "123456";
		public	  String diveNotes ="wizard-dive-notes";
		public	  String fishInput ="//div[@id='fish_spotted_container']/ul/li/input";
		public	  String saveDiveBut = "link=Save";
		public	  String deleteDiveBut = "link=Delete";
		public	  String cancelDiveBut = "link=Cancel";
	//	public	  String editButton = "//img[@alt='Edit']";
		public	  String editButton = "name=modal";
		public	  String fbCommFrame1 = "//a[@class='UIImageBlock_Image UIImageBlock_ICON_Image']"; 
		public	  String fbCommFrame2 = "//div[3]/div[5]/div[2]/div[2]//span";
		public	  String fbCommFrame3 ="link=Facebook social plugin"; 
		public	  String fbCommFrame4 =	"//form[@action='/ajax/connect/feedback.php']";

		public String panicButton = "id=Panic_mg";
		
		public String tab_overview = "//li[@id='tab_overview_link']/a";
		public String tab_pict = "//li[@id='tab_pictures_link']/a";
		public String tab_map = "//li[@id='tab_map_link']/a";
		public String tab_profile = "id=tab_profile_link";
		
		
		
		
	//	String time = new SimpleDateFormat("dd.MM.yyyy HH.mm.SS").format(new java.util.Date());

	
		
		
//	@After
		public void close() throws Exception {
			
			closeBrowser();
		}
	
		public void register() throws InterruptedException {
			System.out.println("Regisetring new user: " + randomTestUsername);
		//	open(url+"/login/register");
			open(url+"login/register");
		
			waitForElement("//div[@id='register_user_info']/input");
			type("//div[@id='register_user_info']/input", randomTestUsername +"@diveboard.com"); //.com
		//	sel.typeKeys("//div[@id='register_user_info']/input", "m");
			
			waitForElement("id=email_ok");
			
			type("//div[@id='register_user_info']/input[2]", userPass);
			type("id=user_password_confirmation", userPass);
			type("id=user_vanity_url", randomTestUsername);
			waitForElement("id=username_ok");
			type("id=user_nickname", username);
			verifyEquals("Keep Me in the Loop:", getText("css=#register_newsletter > label"));
			verifyEquals("Please Type the Two Words:", getText("css=span > label"));
			verifyTrue(isElementPresent("css=td.recaptcha_r3_c2"));
			verifyTrue(isElementPresent("id=user_email"));
			verifyTrue(isElementPresent("id=password-clear"));
			verifyTrue(isElementPresent("id=user_submit"));
			verifyTrue(isElementPresent("id=forgot_pwd"));
			verifyTrue(isElementPresent("id=forgot_email"));
			click("//div[@id='register_button']/input");
			//sel.waitForPageToLoad("30000");
		//	waitForElement("css=div.main_content_box.logbook_profile");
			
			
			waitForElement("css=img.showhome");
			user_url = getWebDriver().getCurrentUrl() ;
			
		//	String	first_user_name = fb_user_name.substring(0, fb_user_name.indexOf(' '));
			
			if (getText("css=span.header_title").startsWith("Test-User"))
								
			System.out.println("New user registered");
			else fail("could not find " + username +" in css=span.header_title on page " + getWebDriver().getCurrentUrl());
		}
		
		
		public void accLogin() throws InterruptedException {
			
			open(url+"/login/register");
			waitForElement("//div[@id='register_user_info']/input");
		
			System.out.println("Login with password..");
			type("id=user_email", email);
			try{
			type("id=user_password", userPass);
			} catch (Exception e) {
				sel.type("id=user_password", userPass);
			}
			
			click("id=token");
			click("id=user_submit");
			sel.waitForPageToLoad("30000");
		//	waitForElement("css=div.main_content_box.logbook_profile"); 
			waitForElement("css=span.header_title");
			verifyTrue(isVisible("link=See Profile"));
		//	String	first_user_name = fb_user_name.substring(0, fb_user_name.indexOf(' '));
			
			if(sel.isVisible("link=See Profile"))
				click("link=See Profile");
			waitForNotVisible("link=See Profile");
			
			if (getText("css=span.header_title").startsWith("Test-User"))
			System.out.println("logged in successful");
		
			else fail("could not find " + username +" in css=span.header_title on page " + getWebDriver().getCurrentUrl());
		}

		
		
	@AfterFailure
    public void captureScreenShotOnFailure(Throwable failure) throws InterruptedException, IOException {
        // Get test method name
        
		
		String testMethodName = null;
		String failureMess =   null;
        for (StackTraceElement stackTrace : failure.getStackTrace()) {
            if (stackTrace.getClassName().equals(this.getClass().getName())) {
                testMethodName = stackTrace.getMethodName();
                failureMess =        failure.getMessage();
                break;
            }
        }
        
   //     sel.captureScreenshot("screenshots/" + this.getClass().getName() + "."   + testMethodName + ".png");
        if (testMethodName == null) {
        	testMethodName = String.valueOf(System.currentTimeMillis());
        }
        
        
        //avoid the loop
        if (testMethodName.equals("captureScreenShotOnFailure")) 
        {
        	 closeBrowser();
        }
       
  //      System.out.println("Test failed ( "+failureMess +"), sending panic screenshot..");
        

        
        
    	if( local)
    	{
          String path = System.getProperty("user.dir");
          //    String fullPath = (path + File.separator +"screenshot" + File.separator + testMethodName + ".png");
          File f = new File(path + File.separator +"screenshot" + File.separator + testMethodName + ".png");
          //	sel.captureEntirePageScreenshot(f.getAbsolutePath(), "");

          System.out.println("Test failed: "+ failureMess + " \nMethod Name is '" +testMethodName + "'" 
        			+ "\n Making screenshot on  " + f.getName()  );
          
          makeScreenshot (f.getName());
    	}
        
 
    	else
    	{
    		
            System.out.println("Test failed: "+ failureMess + " \nMethod Name is '" +testMethodName + "'" 
                    		+ "\n The screenshot is made  \\screenshot\\" + testMethodName  + ".png");
            
        //    sel.captureEntirePageScreenshot("C:\\screenshot\\" + testMethodName + ".png", "");
           try{
            makeScreenshot("screenshot\\" + testMethodName + ".png");
           } catch(Exception e)
           { System.out.println("Could not make screenshot! " +e.getMessage());}
    	}
    	
    
    	
    	// we decided to change screenshot making with "Panic" :D
    	/*
        waitForElement(panicButton);
        
        click(panicButton);
        
        waitForElement("id=contact_subject");
        
		sel.type("id=contact_subject", "Test failed! ");
		
		sel.type("name=ticket[message]", "Test failed: "+ failureMess + " \nMethod Name is '" +testMethodName + "'" 
					+ "\n The screenshot is made on VM " + "C:\\screenshot\\" + testMethodName + ".png");
		
	//	verifyEquals("on", sel.getValue("name=screenshot"));
		
		sel.typeKeys("name=email", "2_angel@bk.ru");
		
		
		waitForElement("name=display_name");
		click("name=display_name");
        sel.type("name=display_name", "");
		sel.type("name=display_name", randomTestUsername );
		Thread.sleep(1000);
		//click Send button
		click("css=button.uvStyle-button");
		
		waitForElement("link=Send another message");
		
				//close panic window
		click("css=button");
        */
     
    	closeBrowser();

	}



	
	protected  void  waitForVisible(String element) throws InterruptedException {
			
		for (int second = 0;; second++) {
			if (second >= minute) fail("FAIL: Element "+element +" was not found on page " + getWebDriver().getCurrentUrl());
			try { if (isVisible(element)) break; } 
			catch (Exception e) {System.out.println(e.getMessage());}
			Thread.sleep(1000);
		
						
		}	
		}
	
	
	protected	void waitForVisibleSel(String element) throws InterruptedException {
		
	for (int second = 0;; second++) {
		if (second >= minute) fail("FAIL: Element "+element +" was not found on page " + getWebDriver().getCurrentUrl());
		try { if (sel.isElementPresent(element)) break; } 
		catch (Exception e) {System.out.println(e.getMessage());}
		Thread.sleep(1000);
	
	}	
	}
		
	protected  void  waitForNotVisible(String element) throws InterruptedException {
		
		for (int second = 0;; second++) {
			if (second >= minute) fail("Element "+element +" is visible on page " + getWebDriver().getCurrentUrl());
			try { if (!isVisible(element)) break; } 
			catch (Exception e) {}
			Thread.sleep(1000);
			}	
	}

protected  boolean  waitAndVerifyVisible(String element) throws InterruptedException {
		
		for (int second = 0;; second++) {
			if (second >= minute/2) 
				{
				System.out.println("!WARNING: Element "+element +" is NOT visible on page " + getWebDriver().getCurrentUrl());
				return false;	
				}
			try { if (sel.isVisible(element)) return true; } 
			catch (Exception e) {}
			Thread.sleep(1000);
			}
		
	}

protected  void  waitAndVerify(String element) throws InterruptedException {
	
	for (int second = 0;; second++) {
		if (second >= minute/2) 
			System.out.println("!WARNING: Element "+element +" is NOT found on page " + getWebDriver().getCurrentUrl());
		try { if (isElementPresent(element)) break; } 
		catch (Exception e) {}
		Thread.sleep(1000);
		}	
}

protected void waitForDiveLink() throws InterruptedException {
	for (int second = 0;; second++) {
	if (second >= minute) fail("# simbol is in link " + getWebDriver().getCurrentUrl());
	try { if (! (getWebDriver().getCurrentUrl().lastIndexOf('#')>0)) break; } 
	catch (Exception e) {}
	Thread.sleep(1000);
	}
}


	public  void logout() throws InterruptedException {
		System.out.println("Loggin out..");
		waitForElement("//img[@alt='logout']");
			 
				click("//img[@alt='logout']");
				
				
				for (int second = 0;; second++) {
					if (second >= minute) fail("Could not logout!");
					try { if (isElementPresent("//img[@alt='Join now']") && 
					 (isElementPresent("//img[@alt='sign up']"))
					)
					{	System.out.println("User logout sucessful");
						break;}
					} 		catch (Exception e) {}
					Thread.sleep(1000);
			}
			
			
		}


	public  String createTestFBUser() throws InterruptedException {

		open(url+"/admin/testfbusergen/all");
		for (int second = 0;; second++) {
			if (second >= minute) fail("Could not find Test Userid!");
			try { if (isElementPresent("id=userid")) break; } 
			catch (Exception e) {System.out.println("Could not find Test Userid");}
			Thread.sleep(1000);
		}
		
		String	user_id = getText("id=userid");
			 	String	fb_user_login_url = getText("loginurl");
	//		 	String	fb_user_password = getText("password");
		
		open(fb_user_login_url);
		sel.waitForPageToLoad("50000");
		if (!isElementPresent("//h1[@id='pageLogo']/a"))
		{	open(fb_user_login_url);
			sel.waitForPageToLoad("50000");}
				 
			if (!isElementPresent("//h1[@id='pageLogo']/a")) 
			System.out.println("Could not create test FB user!");
			else {
			 	Full_fb_user_name = getText("//div[@id='pagelet_header_personal']/div/div[2]/h1/span");
			//	fb_user_name = Name + Surname
			//	Ful_fb_user_name.indexOf(' ');
			//	Ful_fb_user_name.lastIndexOf(' ');
				
			fb_user_name = Full_fb_user_name.substring(0, Full_fb_user_name.indexOf(' '))+Full_fb_user_name.substring(Full_fb_user_name.lastIndexOf(' '),Full_fb_user_name.length());
			System.out.println("Test FB user created, ID = " +user_id + ", Name is " + fb_user_name );
			return  user_id ;
				
				
			}
			return null;
		
	}
	
	

	public  void loginFB() throws Exception {
		System.out.println("Login existing test FB user");
		open(url);
	//	sel.waitForPageToLoad("500000");
		
		waitForElement("//img[@alt='Join now']");
		
		// click login
		
		click("//img[@alt='Join now']");
	//	sel.waitForPageToLoad("50000");
		waitForVisible("//img[@alt='Login with Facebook']");
		click("//img[@alt='Login with Facebook']");
		
		waitForElement("css=img[alt='logout']");
		

		waitForElement("id=main_content_area");
	
		String	first_user_name = fb_user_name.substring(0, fb_user_name.indexOf(' '));
		
		if ((getText("css=span.header_title").startsWith(first_user_name))//check FB name
			//	 &&!(isElementPresent("css=img[alt=Add as buddy]")) // there is not  "Add as buddy" button 
		)
		System.out.println("Test user logged in sucessful");
	else fail("Could not login test FB user!");
		
			
	}
	


	public  void loginTempFBUser() throws Exception {
		open(url+"/");
		sel.waitForPageToLoad("500000");
		// click login
		click("//img[@alt='Join now']");
	
		waitForElement("//img[@alt='Login with Facebook']");
		click("//img[@alt='Login with Facebook']");
	//	sel.waitForPageToLoad("50000");
		
		verifyTrue(isElementPresent("css=img[alt=Diveboard]"));
		waitForElement("css=span.header_title");		
		verifyEquals("Final step : Select your personal address on Diveboard", getText("css=span.header_title"));
		verifyTrue(getText("//div[@id='register_user_info']/div").matches("^exact:The link will point to your logbook homepage, it's your personal Diveboard place so choose it wisely[\\s\\S]*!$"));
		verifyTrue(getText("css=span.register_input_explain").matches("^exact:[\\s\\S]* The URL can be changed on the settings pane, but all direct links to your logbook or dives will break upon change\\.$"));
		System.out.println("Select your personal address on Diveboard: " + sel.getValue("id=user_vanity_url"));
		verifyEquals("COMMUNITY AND HELP", getText("css=div.footer_two > ul > li > strong"));
		verifyTrue(isElementPresent("css=div.connect_top.clearfix"));
		verifyTrue(isElementPresent("css=div.footer_two"));
		verifyTrue(isElementPresent("css=div.footer_one"));
		verifyTrue(isElementPresent("css=div.footer_three"));
		verifyTrue(isElementPresent("//div[@id='footer_container']/div[3]"));
		click("id=user_submit");
	//	sel.waitForPageToLoad("30000");

		/*
		for (int second = 0;; second++) {
			if (second >= minute) fail("Could not find logout button!");
			try { if (isElementPresent("//img[@alt='logout']")) break; } 
			catch (Exception e) {
				System.out.println(e.getMessage());
			}
			Thread.sleep(1000);
		}
*/
			waitForVisible("//img[@alt='logout']");
				
		for (int second = 0;; second++) {
			if (second >= minute) fail("Main page was not opened for new user");
			try { 
				
		String	first_user_name = fb_user_name.substring(0, fb_user_name.indexOf(' '));
		
				if ((getText("//span[@class='header_title']").startsWith(first_user_name)) &&
						(getText("css=span.half_box_data").equals("0")))  // Dives on Diveboard:0
								break;
				} 
			catch (Exception e) {
				System.out.println(e.getMessage()); return;
				
			}
			Thread.sleep(1000);
		}

//	if (	
	//	!(isElementPresent("css=img[alt=Add as buddy]")) // there is not  "Add as buddy" button 
		
	{ user_url = getWebDriver().getCurrentUrl();
		System.out.println("Test user logged in sucessful, url: " + user_url);
	
	}
//	else System.out.println("Could not login test FB user!");	
	}


	public  void deleteCurrentDive(String diveLink) throws InterruptedException {
		open(diveLink);
		sel.waitForPageToLoad("50000");
		click(editButton);
	//	waitForElement("link=Delete Dive");
		
		for (int second = 0;; second++) {
			if (second >= minute) fail("Could not find Delete Dive button!");
			try { if (isElementPresent(deleteDiveBut)) break; } catch (Exception e) {
				
			}
			Thread.sleep(1000);
		}

		click(deleteDiveBut);
		for (int second = 0;; second++) {
			if (second >= minute) fail("Could not find Delete Dive button!");
			try { if (isElementPresent("//button[@type='button']")) break; } catch (Exception e) {
				
			}
			Thread.sleep(1000);
		}

		click("//button[@type='button']");
		for (int second = 0;; second++) {
			if (second >= minute) fail("Could not find mask");
			try { if (!isElementPresent("mask")) break; } catch (Exception e) {}
			Thread.sleep(1000);
		
		}
		System.out.println("dive deleted");
	}
	
	public   void deleteTempFBUser(String user_id)
		{  open(url+"/admin/testfbuserdel/" + user_id);
		sel.waitForPageToLoad("50000");
		
		if (getText("css=body").equals("User deleted")) {
			System.out.println("User deleted sucsessful");
		}
		else System.out.println("Could not delete test user!");
		}

	public  void openSettings() throws InterruptedException
	{	open(url+"settings");
		sel.waitForPageToLoad("50000");
		for (int second = 0;; second++) {
			if (second >= minute) fail("Could not open Settings!");
			try { if (sel.isVisible("css=div.settings_sidebar")) break; } 
			catch (Exception e) {}
			Thread.sleep(1000);
				}
	}
	
	public    void changeUnitSystemToImperial() throws InterruptedException {
		openSettings();
			try{
			click("menu_4");
			select("pref_units", "value=2");
			click("save_form");
			}catch(Exception e) {System.out.println("Could not change to Imperial!"); return;}
			System.out.println("Settings changed to Imperial"); 
			click("//a[@id='user_dives_url']");
			sel.waitForPageToLoad("1000000");
		//	WaitForElement("//div[@id='main_content_area']/div[1]/ul[1]/li[1]/span");
			
			for (int second = 0;; second++) {
				if (second >= minute) fail("Could not open dive page!");
				try { if (isElementPresent("//div[@id='main_content_area']/div[1]/ul[1]/li[1]/span")) break; } 
				catch (Exception e) {System.out.println(e.getMessage());}
				Thread.sleep(1000);
			
			}
			
			}
			
	public    void changeUnitSystemToMetric() throws InterruptedException {
			openSettings();	
				
			
				try{
					click("menu_4");
				select("pref_units", "value=1");
				click("save_form");
				}catch(Exception e) {System.out.println("Could not change to Metric! " + e.getMessage()); return;}
				System.out.println("Settings changed to Metric"); 
				
				click("//a[@id='user_dives_url']");
				sel.waitForPageToLoad("1000000");
			//	WaitForElement("//div[@id='main_content_area']/div[1]/ul[1]/li[1]/span");
				
				
				for (int second = 0;; second++) {
					if (second >= minute) fail("Could not open dive page!");
					try { if (isElementPresent("//div[@id='main_content_area']/div[1]/ul[1]/li[1]/span")) break; } 
					catch (Exception e) {System.out.println(e.getMessage());}
					Thread.sleep(1000);
				
				}	
				
			}


	public void picturescheck() throws InterruptedException
	{
		click(tab_pict);
		waitForVisible("id=galleria");
	//	int num_of_Pict = Integer.parseInt(getText("//span[@class='galleria-total']"));	
	//	int num_of_Pict = (Integer) sel.getCssCount("css=div.galleria-image > img");
	
		int num_of_Pict = sel.getXpathCount("//div[@id='galleria']//img").intValue();
		
		System.out.println("Number of uploaded pictures = " + (num_of_Pict));
		
		click("//div[@id='galleria']/div/div/img");
		waitForVisible("id=cee_next");
				
		verifyFalse(isElementPresent("id=cee_prev"));
		
		
		for(int i=1; i<=num_of_Pict; i++)
		{
	
			if (isVisible("id=cee_img"))
				System.out.println(i + " picture local adress: " + getAttribute("//img[@id='cee_img']@src"));
			if (isVisible("id=cee_vid"))
				System.out.println(i + " VIDEO adress: " + getAttribute("//div[@id='cee_vid']/object@data"));
			
			if(isVisible("id=cee_next"))
			click("id=cee_next");
			
			Thread.sleep(1000);
				for (int second = 0;; second++) {
					if (second >= minute) 
						System.out.println("WARNING! Element 'id=cee_img' or 'id=cee_box' was not found on page " + getLocation());
					try { if (isVisible("id=cee_img") || isVisible("id=cee_vid")) break; } 
					catch (Exception e) {System.out.println(e.getMessage());}
					Thread.sleep(1000);
				}
		}
		
	
		click("id=cee_closeBtn");
		waitForNotVisible("id=cee_img");
		Thread.sleep(1000);
	}
	
	
	
	public void spotSearch(String whatToType, int lineNumber) throws InterruptedException
	{ String element = "//ul[@class='ui-autocomplete ui-menu ui-widget ui-widget-content ui-corner-all']/li["+lineNumber+"]";
		click(tab_map);
		waitForVisible("id=createnewspot_back");
		waitForElement("spotsearch");
		
		// * searching for a spot

		type("spotsearch",whatToType);
		
		for (int second = 0;second <= minute; second++) {
			if (second == 15) 
			{
				System.out.println("location was not filled in. trying one more time..."); 
				sel.type("spotsearch", "");
				sel.typeKeys("spotsearch", whatToType);
				
			}
				
			try { 
				if (isElementPresent(element)) break; 
				} catch (Exception e) {}
			
			Thread.sleep(1000);
		}
		
		click(element);
		
				
		waitForVisible("id=wizard-spot-flag");
	}
	
	
	public void verifyText(String element, String  text)
	{
		if(	!(getText(element).contains(text)||(getText(element).equalsIgnoreCase(text) )))
			{System.out.println("WARNING! text is differ for element " +element);
			System.out.println("real text is: "+ getText(element) +  "  and expected: " + text);
			}
		
	}
	
	
}
	
	

