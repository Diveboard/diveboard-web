

import org.junit.Test;

import diveboard.CommonActions;

public class CreateFullNewDive  extends CommonActions {

	public String url_new_dive;
	public String test_note = "a test note for this \"TEST\" dive at , near the village of \n<a> wonderful dive </a>; with me & everyone !";

	public String graph_small = "M1,15L1,15L2,25L3,29L4,33L5,36L6,39L7,42L8,45L8,50L9,52L10,60L11,64L12,65L13,66L14,66L15,67L16,67L17,67L18,67L19,67L20,64L21,67";
	public String prifile_graph = "M25,20L25,20L28,59L31,73L34,87L37,101L40,112L43,123L46,133L49,151L52,162L55,190L58,204L61,211L63,215L66,215L69,218L72,218L75,218L78,218L81,218L84,204L87,218L90,218L93,218L96,218L99,218L102,222L105,222L108,218L111,222L114,222L117,218L120,218L123,211L126,215L129,222L132,222L135,215L137,218L140,218L143,222L146,222L149,211L152,204L155,211L158,208L161,208L164,215L167,215L170,208L173,208L176,218L179,218L182,218L185,215L188,218L191,232L194,236L197,225L200,239L203,247L206,264L209,271L211,275L214,261L217,261L220,275L223,282L226,271L229,264L232,268L235,282L238,307L241,321L244,324L247,321L250,328L253,342L256,353L259,349L262,339L265,342L268,342L271,339L274,335L277,331L280,310L283,278L285,250L288,247L291,239L294,257L297,264L300,264L303,261L306,254L309,250L312,239L315,239L318,236L321,239L324,232L327,208L330,186L333,176L336,158L339,151L342,144L345,137L348,147L351,147L354,162L357,162L360,169L362,172L365,158L368,140L371,144L374,144L377,147L380,151L383,147L386,144L389,140L392,140L395,144L398,144L401,151L404,155L407,158L410,158L413,165L416,165L419,169L422,165L425,172L428,165L431,155L434,155L436,140L439,137L442,137L445,137L448,130L451,133L454,140L457,140L460,137L463,144L466,133L469,130L472,130L475,133L478,123L481,116L484,112L487,101L490,101L493,101L496,94L499,98L502,98L505,91L508,87L510,80L513,80L516,84L519,80L522,77L525,77L528,77L531,66L534,70L537,70L540,66L543,66L546,66L549,62L552,59L555,66L558,66L561,70L564,73L567,70L570,62L573,52L576,48L579,52L582,52L584,55L587,59L590,59L593,66L596,66L599,70L602,70L605,66L608,62L611,59L620,20L25,20";
	
	public String fav_pic_local_addr;
	
	@Test
	public void test_FullDive() throws Exception {
		
	fb_user_id =	createTestFBUser();
		loginTempFBUser();
	//	register();
		createFullNewDive();
		changeUnitSystemToMetric();
		viewDiveInMetric();
		changeUnitSystemToImperial();
		viewDiveInImperial();
		viewDive();
		deleteCurrentDive(url_new_dive);
		deleteTempFBUser(fb_user_id);
		closeBrowser();
	}

	


	public void viewDiveInImperial() throws Exception {
		System.out.println("View dive in Imperial");
		open(url_new_dive);
		//* Dive information displayed on main page : date, time, depth, duration, temperatures, notes, fishes [if available - if not then correctly displayed]
	
		
		verifyTrue(getText("//div[@id='tab_overview']/div[1]/ul/li[2]").equalsIgnoreCase("Max Depth: 94.2ft Duration:66mins"));
		verifyTrue(getText("//div[@id='tab_overview']/div[2]/div[3]/ul/li[2]").
				contains("Temp: Surf 91") 
				&&
				getText("//div[@id='tab_overview']/div[2]/div[3]/ul/li[2]").
				contains("F Bottom 66"));
	
	
		
	System.out.println("Dive in Imperial checked");
	}


	private void viewDiveInMetric()  throws Exception {
		System.out.println("View dive in Metric");	
		
		open(url_new_dive);
		verifyTrue(getText("//div[@id='tab_overview']/div[1]/ul/li[2]").equalsIgnoreCase("Max Depth: 28.7m Duration:66mins"));
		
		verifyTrue(getText("//div[@id='tab_overview']/div[2]/div[3]/ul/li[2]").
				contains("Temp: Surf 33") 
				&&
				getText("//div[@id='tab_overview']/div[2]/div[3]/ul/li[2]").
				contains("C Bottom 19"));
		
		//	viewDive();
	
			
			System.out.println("Dive in Metric checked");	
				
	}
		

private void viewDive() throws InterruptedException
{	open(url_new_dive);
	
	sel.mouseMoveAt("//div[@id='graph_small']", "80,-80");
	waitForVisible("graph_small");
	Thread.sleep(1000);
 	System.out.println("Verifying small graph..");
	verifyEquals("true", sel.getEval("window.document.getElementById(\"graph_small\").innerHTML.indexOf(\"" + graph_small + "\") > 0"));
	verifyTrue(getText("//div[@id='tab_overview']/div[1]/ul/li[1]").equalsIgnoreCase("Date: 2010-07-31 - 14:34"));
	verifyFalse(sel.isElementPresent("id=add_buddy"));
	verifyTrue(getText("css=div.divers_comments").contains("DIVER'S NOTES "+test_note));
	
	//	verifyTrue(sel.isTextPresent(test_note));  css=div.divers_comments
	//	verifyEquals("Dive type : recreational, traaining, night dive, deep dive, drift, wreck, cave, reef, photo, research, test1, test2, test3, test4, test5", 
		//				getText("css=div.triple_box > ul > li"));
		
	//	verifyTrue(sel.isTextPresent("Dive type : recreational, training, night dive, deep dive, drift, wreck, cave, reef, photo, research, test1, test2, test3, test4, test5"));
		verifyEquals("DIVE TYPE : recreational, training, night dive, deep dive, drift, wreck, cave, reef, photo, research, test1, test2, test3, test4, test5", getText("css=div.triple_box > ul > li"));
		verifyTrue(isElementPresent("//div[@id='tab_overview']/div[3]/div[1]/ul/li[1]/a/img")); 
		verifyTrue(isElementPresent("//div[@id='tab_overview']/div[3]/div[2]/ul/li[1]/a/img"));
		verifyEquals("Blue Hole", getText("//div[@id='main_content_area']/div[1]/ul[1]/li[1]/span"));
		verifyEquals("Malta", getText("country_title"));
		verifyTrue(getText("//li[2]/a[2]").contains("Gozo"));
		verifyTrue(getText("//div[@id='main_content_area']/div/ul/li[2]/a[3]").contains("Med"));
		
		System.out.println("Checking Species spotted:");
		verifyTrue( getText("//div[@id='tab_overview']/div[2]/div[3]/ul/li[3]/strong").
				equalsIgnoreCase("Species spotted:"));
		verifyEquals("Gulf grouper", getText("//a[@href='http://www.eol.org/pages/204294']"));
		
		sel.mouseOver("link=Gulf grouper");
		waitForVisible("//img[@src='http://content6.eol.org/content/2009/05/19/22/45884_medium.jpg']");
		verifyEquals("Mycteroperca jordani (Jenkins and Evermann, 1889)\nData provided by EOL.org",
				getText("css=div.qtip-content.qtip-content"));
		
		verifyTrue(isElementPresent("//img[contains(@src,'http://content6.eol.org/content/2009/05/19/22/45884_medium.jpg')]"));
		
		sel.mouseOut("link=Gulf grouper");
		waitForNotVisible("//img[@src='http://content6.eol.org/content/2009/05/19/22/45884_medium.jpg']");
		
		
		sel.mouseOver("link=Anemonefishes and Clownfishes");
		waitForVisible("//img[contains(@src,'http://content9.eol.org/content/2009/07/24/11/24287_medium.jpg')]");
		verifyTrue(	getText("css=div.qtip-content.qtip-content").contains("Amphiprion\nData provided by EOL.org"));
		
		verifyTrue(isElementPresent("//img[contains(@src,'http://content9.eol.org/content/2009/07/24/11/24287_medium.jpg')]"));
		
		sel.mouseOut("link=Anemonefishes and Clownfishes");
		waitForNotVisible("//img[contains(@src,'http://content9.eol.org/content/2009/07/24/11/24287_medium.jpg')]");
		
	//	verifyFalse(sel.isTextPresent("dolphin"));
		
		System.out.println("Checking pics:");
		verifyTrue(isElementPresent("featured_pic"));
		verifyTrue(isElementPresent("//img[@id='featured_pic'][contains(@src ,'IMG_4564.JPG')]"));
		verifyTrue(sel.isVisible("//div[@id='graph_small']"));
		
	// * Preferred picture on main dive page

		verifyTrue(sel.isElementPresent("//div[2]/div/div/div/div/a/img[contains(@src, '"+fav_pic_local_addr+"')]"));
		
		//map
		
		click("css=div.triple_box_content > a > img");
		waitForElement("tab_gmap_holder");
	//	verifyTrue(sel.isElementPresent("css=div[title=Drag to zoom] > img"));  // zoom is available
		verifyTrue(sel.isElementPresent("//a[@id='tab_map_link' and @class = 'active']")); //map tab is active
	
		
		//pictures
		picturescheck();
	
		
		
//profile
		click(tab_profile);
	//	waitForVisible("//div[@id='tab_profile']/h1");
		 
	 		waitForVisible("graphs");
	 		 Thread.sleep(1000);
			 System.out.println("Verifying profile graph..");
		verifyEquals("true", sel.getEval("window.document.getElementById(\"graphs\").innerHTML.indexOf(\"" + prifile_graph + "\") > 0"));
		
	}

	private void createFullNewDive() throws InterruptedException {
		open(url+"/");
		click("create_dive_2");
		System.out.println("new dive creating..."); 
		//LOCATION
		
		waitForVisible("//div[@class='box_row_w']");

		spotSearch("blu ho go",3);
	
		// Profile
		System.out.println("Profile.."); 
		click(tab_profile);
		click("wizard_import_btn");
		waitForVisible("wizard_plugin_detect_extract");
		

		select("wizard_computer_select1", "label=Emulator 1 - 1 dive - Using Suunto driver");
		click("wizard_plugin_detect_extract");
		waitForNotVisible("id=progressStatus");	
		
		waitForVisible("wizard_dive_profile");
		
		verifyEquals("2010-07-31", sel.getValue("wizard-date"));
		verifyEquals("14", sel.getValue("wizard-time-in-hrs"));
		verifyEquals("34", sel.getValue("wizard-time-in-mins"));
		verifyEquals("66", sel.getValue("wizard-duration-mins"));
		verifyEquals("28.7", sel.getValue("wizard-max-depth"));
		verifyEquals("Delete profile or Import from file/computer", getText("wizard_delete_graph"));
		
		click(tab_overview); 
		waitForVisible("wizard-surface-temperature");
		type("wizard-surface-temperature", "33");
		type("wizard-bottom-temperature", "19");
		type("stop_time", "3");
		
		// * with safety stops for profile
		click("addsafetystops");
	//	click("//div[@id='profile_table']/table[1]/tbody/tr[6]/td[2]/input[1]");
		type("//tr[2]/td[2]/input", "6");
		type("//tr[2]/td[2]/input[2]", "3");
		click("addsafetystops");
		type("//tr[3]/td[2]/input", "7");
		type("//tr[3]/td[2]/input[2]", "4");
		click("link=Del");
		
		// * with Dive Notes
		
		System.out.println("Dive Notes.."); 
	//	click("link=Dive Notes");
		
		waitForVisible(diveNotes);
		

		type(diveNotes, test_note);
		
		click("//input[@value='recreational']");
		click("//input[@value='training']");
		click("//input[@value='night dive']");
		click("//input[@value='deep dive']");
		click("//input[@value='drift']");
		click("//input[@value='wreck']");
		click("//input[@value='cave']");
		click("//input[@value='reef']");
		click("//input[@value='photo']");
		click("//input[@value='research']");
		sel.type("wizard_divetype_other", "test1, test2, test3,test4,test5");
		
		
		// * with Fish Data
		System.out.println("Fish Data.."); 
	//	click("link=Fish Data");
	
		click(fishInput);
		sel.typeKeys(fishInput, "clown");
		waitForElement("//li[.='Anemonefishes and Clownfishes']");
		
		try {
		sel.mouseOver("//li[.='Anemonefishes and Clownfishes']");
		sel.mouseDown("//li[.='Anemonefishes and Clownfishes']");
		} catch (Exception e) {
			System.out.println("could not add Anemonefishes and Clownfishes!" + e.getMessage());}
		
		click(fishInput);
		sel.typeKeys(fishInput, "grouper");
		
		waitForElement("//li[.='Gulf grouper']");
		
		try {
		sel.mouseOver("//li[.='Gulf grouper']");
		sel.mouseDown("//li[.='Gulf grouper']");
		} catch (Exception e) {
								System.out.println("WARNING! could not add Gulf grouper fish!" + e.getMessage());}

		String pictureLink[][] =		{
				{" https://picasaweb.google.com/103180330852418292309/GreatBarrierReef#5455929773960873746 ", "//img[contains(@src,'https://lh3.googleusercontent.com/-0WQ--QZo9cI/S7dbOQBqRxI/AAAAAAAAFuY/YME-LQbviR4/IMG_4564.JPG')]"},//picasa pic
				{"http://www.facebook.com/photo.php?fbid=134707619941071&set=a.134707603274406.34094.100002055014409&type=1&theater", "//img[contains(@src,'http://a8.sphotos.ak.fbcdn.net/hphotos-ak-snc6/248590_134707619941071_100002055014409_237219_900092_n.jpg')]"},
				{"http://www.flickr.com/photos/sbailliez/3434813100/", "//img[contains(@src,'http://farm4.static.flickr.com/3337/3434813100_6064127dab.jpg')]"},
				{"http://www.dailymotion.com/video/xkoaz3_live-24-heures-moto-2011_auto", "//img[contains(@src,'/user_images/video_')]"},
				{"http://a6.sphotos.ak.fbcdn.net/hphotos-ak-snc6/216041_103492703072973_100002367311036_33469_1227396_n.jpg","//img[contains(@src,'http://a6.sphotos.ak.fbcdn.net/hphotos-ak-snc6/216041_103492703072973_100002367311036_33469_1227396_n.jpg')]"},
				{"http://www.youtube.com/watch?v=dki2v8qoj_w ", "//img[contains(@src,'/user_images/video_')]"},
				{"https://picasaweb.google.com/106006149916198510480/RAZNIVARIE?feat=featured#5639970005814483490", "//img[contains(@src,'https://lh6.googleusercontent.com/-pE3JmCSxuFc/TkUy1qRuGiI/AAAAAAAAER8/_QHlSH1hkOE/111_1.jpg')]"},
	//commented until bug with FB video is fixed
				//			{"http://www.facebook.com/video/video.php?v=179116772166822", "//img[contains(@src,'https://stage.diveboard.com//user_images/video_')]"}
				
				
		};
		
		// * with 	Pictures
		System.out.println("Adding "+ pictureLink.length+ " Pictures/videos:"); 
		click(tab_pict);
		
		waitForVisible("wizard_pict_url");
		
		for(int i = 0; i<pictureLink.length; i++)
		{	System.out.println(i+1 +": "+pictureLink[i][0]);
			clear("wizard_pict_url");	
			type("wizard_pict_url", pictureLink[i][0]);
			click("wizard_add_pict_button");
			waitForNotVisible("//div[@id='galleria-wizard-loading']/img");
			waitForVisible(pictureLink[i][1]);
		//	waitForVisible("//div[@id='galleria-wizard']/div/div[2]/div[2]/div/div["+(i+1)+"]/img");
		}
		/*
		// 1 add picasa pic
		type("wizard_pict_url", "https://picasaweb.google.com/103180330852418292309/GreatBarrierReef#5455929773960873746");
		click("wizard_add_pict_button");
		
	//	waitForElement("//div[@id='galleria-wizard']/div/div[1]/div[1]/div[2]/img");
		
		
		for (int second = 0;; second++) {
			if (second >= 15) 
			{
				System.out.println("button Add was not pressed for unknown reason, try one more time.. ");
				click("wizard_add_pict_button");
				waitForElement("//img[contains(@src,'https://lh3.googleusercontent.com/-0WQ--QZo9cI/S7dbOQBqRxI/AAAAAAAAFuY/YME-LQbviR4/IMG_4564.JPG')]");
			}
			try { if (sel.isElementPresent("//img[contains(@src,'https://lh3.googleusercontent.com/-0WQ--QZo9cI/S7dbOQBqRxI/AAAAAAAAFuY/YME-LQbviR4/IMG_4564.JPG')]")) break; } 
			catch (Exception e) {System.out.println(e.getMessage());}
			Thread.sleep(1000);
		
		}	
		
	

	//2 add fb pic	
		type("wizard_pict_url", " http://www.facebook.com/photo.php?fbid=134707619941071&set=a.134707603274406.34094.100002055014409&type=1&theater");
		click("wizard_add_pict_button");
		
		waitForElement("//img[contains(@src,'http://a8.sphotos.ak.fbcdn.net/hphotos-ak-snc6/248590_134707619941071_100002055014409_237219_900092_n.jpg')]");
		
		
		
		// 3 add flickr pic
		type("wizard_pict_url", "http://www.flickr.com/photos/sbailliez/3434813100/");
		click("wizard_add_pict_button");
		waitForElement("//img[contains(@src,'http://farm4.static.flickr.com/3337/3434813100_6064127dab.jpg')]");
		
		
		//4 add *.jpg url  http://a6.sphotos.ak.fbcdn.net/hphotos-ak-snc6/216041_103492703072973_100002367311036_33469_1227396_n.jpg
		
		type("wizard_pict_url", "http://a6.sphotos.ak.fbcdn.net/hphotos-ak-snc6/216041_103492703072973_100002367311036_33469_1227396_n.jpg");
		click("wizard_add_pict_button");
		waitForElement("//img[contains(@src,'http://a6.sphotos.ak.fbcdn.net/hphotos-ak-snc6/216041_103492703072973_100002367311036_33469_1227396_n.jpg')]");
		
		
		// 5 add youtube video http://youtu.be/i861adrvBZ4
		
		type("wizard_pict_url", "http://youtu.be/i861adrvBZ4");
		click("wizard_add_pict_button");
		waitForElement("//div[@id='galleria-wizard']/div/div[2]/div[2]/div/div[5]/img");
		
		
		// 6 add picasa pic https://picasaweb.google.com/106006149916198510480/RAZNIVARIE?feat=featured#5639970005814483490				
		
		sel.type("wizard_pict_url", "https://picasaweb.google.com/106006149916198510480/RAZNIVARIE?feat=featured#5639970005814483490");
		click("wizard_add_pict_button");
		waitForElement("//div[@id='galleria-wizard']/div/div[2]/div[2]/div/div[5]/img");
		*/
		
		System.out.println("Set favourite picture #3");
		
		// set favourite picture #3
		
	//	click("//div[@id='galleria-wizard']/div/div[2]/div[2]/div/div[3]/img");
	//	click("wizard_pict_set_fave");
		
		
	//WD + FF7 bug : Cannot perform native interaction: Could not load native events component.	
		try{
		dragAndDrop("//div[@id='galleria-wizard']/div/div[2]/div/img[2]", -360,0);
				}catch(Exception e){
					System.out.println("Could not perform dragAndDrop "+e.getMessage());
					}
	//	verifyEquals(getText("favoritepic"), "Favorite pic #3 |");
		
		
		fav_pic_local_addr = sel.getAttribute("//div[@id='galleria-wizard']/div/div/img@src");
		
 //add incorrect link
/*		
		sel.type("wizard_pict_url", "http://youtu.be/1234");
		try{
		click("wizard_add_pict_button");} 
		catch (Exception e) {
			verifyTrue(sel.getAlert().startsWith("Unrecognized picture url, sorry!"));
			verifyTrue(sel.isElementPresent("dialog"));
		}
		
	*/	
		
				
		click(saveDiveBut);
		waitForNotVisible("id=file_spinning");
	//	waitForVisible("link=Facebook social plugin"); //wait for FB comments frame to load
		waitForElement("//div[@id='main_content_area']/div[1]/ul[1]/li[1]/span");
	//	waitForNotVisible("id=dialog");
		
		waitForDiveLink();
		
	//	String host = sel.getEval("window.document.domain");
		url_new_dive = sel.getLocation();
		System.out.println("New Dive created. " + url_new_dive);
		
	}

}
