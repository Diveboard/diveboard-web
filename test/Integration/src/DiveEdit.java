//import org.testng.annotations.Test;
//import org.testng.Assert;
import org.junit.Test;  
import diveboard.SimpleDiveActions;



public class DiveEdit extends SimpleDiveActions {
	public String test_note = "a test note for this nice dive at l'chelle, near the village of \n<a> wonderful dive </a>; with me & everyone ! (This note is not visible outside)";
	public String fav_pic_local_addr;
	String graph_small = "M1,15L1,33L3,39L4,41L6,44L8,51L9,59L11,65L13,73L14,79L16,82L18,84L19,85L21,87L23,89L24,90L26,92L28,93L30,93L31,94L33,94L35,93L36,93L38,91L40,92L41,92L43,91L45,88L46,89L48,89L50,90L51,89L53,88L55,87L56,86L58,86L60,86L61,86L63,86L65,84L66,83L68,81L70,78L72,75L73,73L75,69L77,69L78,69L80,67L82,66L83,65L85,63L87,63L88,63L90,63L92,63L93,64L95,66L97,66L98,62L100,63L102,63L103,63L105,62L107,61L108,60L110,59L112,59L113,59L115,58L117,57L118,54L120,52L122,50L124,50L125,49L127,47L129,45L130,42L132,42L134,42L135,42L137,42L139,40L140,37L142,36L144,36L145,35L147,32L149,32L150,30L152,32L154,31L155,30L157,31L159,31L160,30L162,29L164,27L166,25L167,24L169,22L171,22L172,22L174,22L176,21L177,21L179,21L181,22L182,21L184,21L189,15L1,15";
	String graph_profile = "M25,20L25,87L30,110L36,117L41,131L46,157L52,185L57,209L62,238L68,261L73,275L78,281L83,287L89,293L94,300L99,305L105,313L110,315L115,316L121,318L126,321L131,316L137,317L142,308L147,310L153,311L158,306L163,297L168,299L174,300L179,303L184,302L190,298L195,292L200,288L206,290L211,290L216,290L222,289L227,281L232,276L238,270L243,259L248,249L253,239L259,223L264,223L269,224L275,215L280,212L285,209L291,203L296,202L301,203L307,203L312,200L317,205L323,211L328,213L333,199L338,201L344,200L349,200L354,199L360,195L365,192L370,188L376,187L381,186L386,184L392,180L397,169L402,162L408,153L413,151L418,149L423,142L429,132L434,121L439,121L445,123L450,124L455,122L461,114L466,104L471,99L477,99L482,96L487,85L493,86L498,78L503,83L508,82L514,78L519,81L524,80L530,75L535,73L540,66L546,58L551,54L556,48L562,48L567,46L572,46L578,44L583,44L588,45L593,46L599,44L604,42L620,20L25,20";

@Test
	public void test_DiveEdit() throws Exception {
		
		fb_user_id = createTestFBUser();
		loginTempFBUser();
		
		changePreferences();
		
		//* cancel creation new dive(exit without saving changes)
		cancelCreation();
		emptyProfileCheck();
		
		createSimpleNewDive();
		
		editDive();
					
		logout();
		
		checkDiveOutside();
	
		loginFB();
		
		checkEditedDive();
		
		deleteTempFBUser(fb_user_id);
		closeBrowser();
		
	}

private void cancelCreation() throws InterruptedException {
	System.out.println("Creating new dive..");
	open(url+"/");
	click("create_dive_2");
	waitForVisible(saveDiveBut);
//	click(tab_map);
//	waitForVisible("id=createnewspot_back");
	
	//LOCATION  choose spot

	spotSearch("Russia", 2);
	
	waitForElement("//img[@src='/img/flags/ru.gif']"); //russian flag
			
//	verifyTrue(getText("css=#correct_submit_spot_data > label").equals("Search for another spot or correct data"));

//	verifyTrue(isElementPresent("createnewspot_cancel"));
	
	
	click(tab_overview);
	// Profile
	
	//* with only the mandatory information

	type("wizard-date", date);
	
	type("wizard-time-in-hrs", time_hrs);
	type("wizard-time-in-mins", time_mins);
	type("wizard-duration-mins", dive_duration);
	type("wizard-max-depth", max_depth_in_ft);
	
	System.out.println("Click Cancel button");
	click(cancelDiveBut);
	
	waitForNotVisible("id=file_spinning");

	waitForDiveLink();

	waitForElement("css=img.showhome");
}


private void emptyProfileCheck() {
	System.out.println("checking empty profile..");
//	verifyEquals("Dived in: No dives logged yet", getText("//div[@id='sidebar']/div/a/ul/li[4]/p"));
	verifyTrue(isElementPresent("//div[@id='main_content_area']/div[2]/div/div/img[@src ='"+url+"/img/no_picture.png']"));
	verifyEquals("Add some information by clicking on the edit   icon to help other divers get to know you.", getText("css=i"));
	verifyEquals("PLACES I'VE DIVED", getText("css=div.double_box.places_dived > strong"));
	verifyEquals("FAVORITE PICTURES", getText("css=#logbook_fav_pics > strong"));
	verifyEquals("SPECIES SPOTTED:", getText("css=#species_spotted > strong"));
	verifyEquals("MY CERTIFICATES", getText("css=#certificates > strong"));
	verifyEquals("FAVORITE DIVES", getText("css=div.double_box.fav_dives > strong"));
	verifyEquals("0", getText("css=span.half_box_data")); //Dives published:
	verifyEquals("0", getText("//div[@id='profile_stat']/ul/li[3]/span")); //Total number of dives:
	verifyTrue(isElementPresent("//div[@id='plusone']/div/a"));
	verifyTrue(isElementPresent("css=span.liketext"));
	verifyTrue(isElementPresent("id=aggregateCount"));
	verifyTrue(isElementPresent("css=div.thumbs_up_icon"));
	verifyTrue(isElementPresent("//a[@id='share_this_link']/img"));
	verifyTrue(isElementPresent("css=img[alt=Edit]"));
	verifyTrue(isElementPresent("link=edit"));
	
}

private void checkDiveOutside() throws InterruptedException {
	System.out.println("check Dive Outside..");	
	
	open(url_new_dive);
	waitForVisible("css=div.double_box");
	
	verifyTrue(getText("css=span.profile_user_name").equalsIgnoreCase(fb_user_name));
	verifyEquals("SCUBA DIVER", getText("css=span.profile_user_badge"));
	verifyEquals("Dived in: Russian Federation", getText("//li[4]/p"));
	verifyTrue(isElementPresent("id=add_buddy"));
	verifyTrue(isElementPresent("id=featured_pic"));
	verifyTrue(isElementPresent("css=div.triple_box_content > a > img"));
	assertFalse(isElementPresent("css=div.jspPane > p"));
	assertFalse(isElementPresent(editButton));
	verifyEquals("DIVE TYPE : recreational, training, night dive, deep dive, drift, wreck, cave, reef, photo, research, test1, test2, test3, test4, test5", getText("css=div.triple_box > ul > li"));
	click("link=See Profile");
	// sel.waitForPageToLoad("30000");
	waitForVisible("css=div.places_dived_container2");
	verifyTrue(isElementPresent("link=2008-08-11 Russian Federation Test1"));
	assertNotEquals(test_note,getText("css=div.fav_dive_body_inner > p"));
	verifyEquals("1", getText("css=span.half_box_data"));
	verifyEquals("1", getText("//div[@id='profile_stat']/ul/li[3]/span"));
	verifyEquals("Russian Federation", getText("//div[@id='profile_stat']/ul/li[4]/span"));
	verifyEquals("39.3m", getText("//div[@id='profile_stat']/ul/li[5]/span"));
	verifyEquals("Test1, Russian Federation", getText("//div[@id='profile_stat']/ul/li[5]/span[2]"));
	verifyEquals("36 mins", getText("//div[@id='profile_stat']/ul/li[6]/span"));
	verifyEquals("Test1, Russian Federation", getText("//div[@id='profile_stat']/ul/li[6]/span[2]"));
	verifyEquals("6", getText("//div[@id='profile_stat']/ul/li[7]/span"));
	verifyEquals("2", getText("//div[@id='profile_stat']/ul/li[8]/span"));
	verifyTrue(isElementPresent("css=img.triple_box_content"));
	verifyTrue(isElementPresent("css=#species_spotted > ul > li > a > img.triple_box_content"));
	verifyEquals("Gulf grouper", getText("link=Gulf grouper"));
	verifyTrue(isElementPresent("//div[@id='species_spotted']/ul/li[2]/a/img"));
	verifyEquals("Anemonefishes and Clownfishes", getText("link=Anemonefishes and Clownfishes"));
	System.out.println("Dive Outside checked.");	
}

private void changePreferences() throws InterruptedException {
	System.out.println("Changing Preferences..");
	openSettings();
	click("menu_4"); // open Preferences
	sel.check("id=pref_auto_public");  // uncheck Publish your dives when complete 
	sel.check("id=pref_auto_fb_share"); //check Enable post to FB wall by default
	click("link=Advanced");
	sel.uncheck("id=pref_share_details_notes");  //Share your dive notes uncheck
	click("//input[@name='sci_privacy' and @value='3']"); //I don't want to share my data 
//	sel.select("pref_units", "value=2"); //Imperial
	sel.uncheck("id=comments_notifs"); //Notify me when someone likes or comments my dives.
	sel.uncheck("id=pref_opt_in"); // Keep me in the loop for more great scuba news.
	click("save_form");
	waitForVisible("id=save_ok");
	
	
}


	private void editDive() throws InterruptedException {
		System.out.println("Edit Dive..");
	open(url_new_dive);
//	sel.waitForPageToLoad("300000");
	waitForVisible("css=div.double_box");
	waitForVisible("css=img.tooltiped-js");
	Thread.sleep(1000);	
	click(editButton); //click edit

	for (int second = 0;second <= minute; second++) {
		if (second == 15) 
		{
			System.out.println("//img[@alt='Edit'] button was not pressed! trying one more time..."); 
			click(editButton);
			Thread.sleep(2000);
		}
			
		try { if (isVisible(saveDiveBut)) break; } catch (Exception e) {}
		Thread.sleep(1000);
	}
	
	
	//	waitForVisible(saveDiveBut);
		
		System.out.println("Spot location edit.."); 

		// * correct data moove spot on the map
		
		click(tab_map);
	//	click("wizard_spot_edit");
		
		System.out.println("correcting spot location on the map");
		

		waitForVisible("//img[@src='http://maps.gstatic.com/mapfiles/google_white.png']");
		waitForVisible("//div[@id='wizardgmaps']/div/div/div/div[6]/div/img");
		Thread.sleep(1000);
		//move yellow spot on the map

		//		dragAndDrop("css=div.gmnoprint > img", 10,10); doesnt work with remote_driver
		
		sel.mouseDown("css=div.gmnoprint > img");
		sel.mouseMoveAt("css=div.gmnoprint > img", "10,10");
		sel.mouseUp("css=div.gmnoprint > img");
		
		type("id=spot-name", "Another spot" );
		
	//	click("wizard_spot_save");
	//	click("fb_post_button");
		click(tab_profile);
		waitForElement("id=ui-dialog-title-dialog-spotchanged");
		verifyText("css=#dialog-spotchanged > p","You made manual changes to the spot you had initially selected. Is it an update or a new spot ?");
		verifyText("css=th","Old version");
		verifyText("//table[@id='spotchanged-table']/tbody/tr/th[2]","Your changes");
		verifyText("//table[@id='spotchanged-table']/tbody/tr[2]/td","Country");
		verifyText("//table[@id='spotchanged-table']/tbody/tr[3]/td","Location");
		verifyText("//table[@id='spotchanged-table']/tbody/tr[4]/td","Name");
		verifyText("//table[@id='spotchanged-table']/tbody/tr[5]/td","Sea / Lake Name");
		verifyText("//table[@id='spotchanged-table']/tbody/tr[6]/td","Latitude");
		verifyText("//table[@id='spotchanged-table']/tbody/tr[7]/td","Longitude");
		verifyText("//table[@id='spotchanged-table']/tbody/tr[8]/td","Zoom");
		verifyText("//table[@id='spotchanged-table']/tbody/tr[9]/td","Precise position");
		
		click("//button[@type='button']");
		
		// Profile
		System.out.println("Profile.."); 
	
		click(tab_profile);
		click("wizard_delete_graph");
		
		click("wizard_import_btn");
	/*
		for (int second = 0;; second++) {
			if (second >= 60) Assert.fail("timeout");
			try { if (sel.isVisible("wizard_plugin_detect_extract")) break; } catch (Exception e) {}
			Thread.sleep(1000);
		}
		*/
		waitForVisible("wizard_plugin_detect_extract");
		
		select("wizard_computer_select1", "label=Emulator 2 - 41 dive - Using Mares M2 driver");
		click("wizard_plugin_detect_extract");
	//	waitForElement("dive_list_selected");
		System.out.println("'Emulator 2 - 41 dive' selected");
	
		
		waitForElement("//select[@id='dive_list_selected']");
		waitForNotVisible("id=progressStatus");
		click("//select[@id='dive_list_selected']");
	//	sel.select("dive_list_selected", "label=2008-08-11 09:05 36mins 39.3m");
		select("//select[@id='dive_list_selected']", "value=27");	
	//	select("//select[@id='dive_list_selected']", "value=27");	
	//	click("dive_list_selected");
		
		
	//	
		waitForVisible("link=Select");
		System.out.println("clicking 'select'");
		try{
		click("link=Select");
		
		}catch(Exception e)
		{	
			System.out.println("Warning: could not click button dive_list_selector_button: " +e.getMessage());
			click("dive_list_selector_button");
			
		}
		
	
	
		waitForVisible("wizard_dive_profile");
		verifyEquals("Delete profile or Import from file/computer", getText("wizard_delete_graph"));
		waitNoElement("//img[@alt='Loading profile...']");
		
		// overview
		
		click(tab_overview);
		verifyEquals("2008-08-11", sel.getValue("wizard-date"));
		verifyEquals("09", sel.getValue("wizard-time-in-hrs"));
		verifyEquals("05", sel.getValue("wizard-time-in-mins"));
		verifyEquals("36", sel.getValue("wizard-duration-mins"));
		verifyEquals("39.3", sel.getValue("wizard-max-depth"));
		
		
		
		waitForVisible("wizard-surface-temperature");
		type("wizard-surface-temperature", "33");
		type("wizard-bottom-temperature", "19");
		
		click("addsafetystops");
		waitForVisible("id=stop_depth");
		type("id=stop_depth", "12");
		type("stop_time", "3");
		
		// * with safety stops for profile
		click("addsafetystops");
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
		type("wizard_divetype_other", "test1, test2, test3,test4,test5");
		
		
		// * with Fish Data
		System.out.println("Fish Data.."); 

	//	click("link=Fish Data");
	
		click(fishInput);
		sel.typeKeys(fishInput, "clown");
	
		
		waitForVisible("//li[.='Anemonefishes and Clownfishes']");
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
								System.out.println("could not add Gulf grouper fish!" + e.getMessage());}

		// * with 	Pictures
		System.out.println("Pictures.."); 
		click(tab_pict);
		
		
		waitForVisible("wizard_pict_url");
	
		
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
		}
		
		
		
		
	
		
		//verify Favorite
		verifyTrue(sel.getAttribute("//img[@class='ui-draggable ui-droppable']@src").
				equals("https://lh3.googleusercontent.com/-0WQ--QZo9cI/S7dbOQBqRxI/AAAAAAAAFuY/YME-LQbviR4/IMG_4564.JPG"));

		// remove 1 picture

		try{
			dragAndDrop("css=img.ui-draggable.ui-droppable", -180,0);
			}catch(Exception e){
				System.out.println("Could not perform dragAndDrop "+e.getMessage());
				}

		verifyFalse(sel.getAttribute("//img[@class='ui-draggable ui-droppable']@src").
				equals("https://lh3.googleusercontent.com/-0WQ--QZo9cI/S7dbOQBqRxI/AAAAAAAAFuY/YME-LQbviR4/IMG_4564.JPG"));

		String favPicUrl = sel.getAttribute("//img[@class='ui-draggable ui-droppable']@src");
		
		// set favorite picture 5
		
		System.out.println("cgange favorite picture to #5");
		try{
			dragAndDrop("//div[@id='galleria-wizard']/div[2]/img[3]", -160,-100);
					}catch(Exception e){
						System.out.println("Could not perform dragAndDrop "+e.getMessage());
						}
		
		//verify favorite changed
		
	verifyFalse(sel.getAttribute("//img[@class='ui-draggable ui-droppable']@src").equals(favPicUrl));
		
	
		
		
		//check new favourite pic num = 4
	//	verifyEquals(getText("favoritepic"), "Favorite pic #4 |");
		
		
//		fav_pic_local_addr = sel.getAttribute("//div[2]/div/div[4]/img@src");
		
 //add incorrect link
/*		
		sel.type("wizard_pict_url", "http://youtu.be/1234");
		try{
		click("wizard_add_pict_button");} 
		catch (Exception e) {
			verifyTrue(sel.getAlert().startsWith("Unrecognized picture url, sorry!"));
			verifyTrue(isElementPresent("dialog"));
		}
		
	*/	
		
		
		
		click(saveDiveBut);
		Thread.sleep(1000);
			// Wait while dive saves
		
		
		
	
		
	//wait for Dive Editor to close
	//	waitForNotVisible("id=dialog");	
		waitForNotVisible("id=file_spinning");
	//	waitForDiveLink();
		Thread.sleep(1000);
		waitForVisible("//div[@id='main_content_area']");
	//	waitForVisible("css=span.fwb.fcb"); 

	//	url_new_dive = sel.getLocation();
		System.out.println("Dive was edit: " + sel.getLocation());
		
	}
	

	private void checkEditedDive() throws InterruptedException {
		System.out.println("Verifying changes..");	
	
		open(url_new_dive);
		sel.waitForPageToLoad("30000");
		waitForElement("//div[@id='tab_overview']/div[1]/ul/li[2]");
		
		verifyTrue(getText("//div[@id='tab_overview']/div[1]/ul/li[2]").equalsIgnoreCase( "Max Depth: 39.3m Duration:36mins"));
		
		verifyEquals("Test1", getText("//div[@id='main_content_area']/div/ul/li[2]/a[2]"));
		verifyEquals("Russian Federation", getText("country_title"));
		 
		verifyTrue(getText("//div[@id='tab_overview']/div[1]/ul/li[1]").equalsIgnoreCase("Date: 2008-08-11 - 09:05"));

	
		verifyTrue(getText("//div[@id='tab_overview']/div[2]/div[3]/ul/li[2]").
				contains("Temp: Surf 33") 
				&&
				getText("//div[@id='tab_overview']/div[2]/div[3]/ul/li[2]").
				contains("C Bottom 19"));
			
		verifyTrue(getText("css=div.divers_comments").contains("DIVER'S NOTES "+test_note));

		
		verifyEquals("DIVE TYPE : recreational, training, night dive, deep dive, drift, wreck, cave, reef, photo, research, test1, test2, test3, test4, test5", getText("css=div.triple_box > ul > li"));	
			
			verifyEquals("true", sel.getEval("window.document.getElementById(\"graph_small\").innerHTML.indexOf(\"" + graph_small + "\") > 0"));
			
				
			verifyTrue(isElementPresent("//div[@id='tab_overview']/div[3]/div[1]/ul/li[1]/a/img"));
			verifyTrue(isElementPresent("//div[@id='tab_overview']/div[3]/div[2]/ul/li[1]/a/img"));
			
		
			verifyText("//div[@id='tab_overview']/div[2]/div[3]/ul/li[3]/strong","SPECIES SPOTTED:");
		
			verifyEquals("Gulf grouper", getText("link=Gulf grouper"));
			verifyEquals("Anemonefishes and Clownfishes", getText("//div[3]/ul/li[3]/a"));
			
		//	verifyFalse(sel.isTextPresent("dolphin"));
			verifyTrue(isElementPresent("featured_pic"));
		
			verifyTrue(isVisible("//div[@id='graph_small']"));
			
		// * Preferred picture on main dive page
	
			verifyTrue(isElementPresent("//div[2]/div/div/div/div/a/img[contains(@src, '"+fav_pic_local_addr+"')]"));
		
			//map
		
			click(tab_map);
			waitForElement("tab_gmap_holder");
		//	verifyTrue(isElementPresent("css=div[title=Drag to zoom] > img"));  // zoom is available
			verifyTrue(isElementPresent("//a[@id='tab_map_link' and @class = 'active']")); //map tab is active
			
			
			//pictures
			picturescheck();

	//profile
			click("tab_profile_link");
			
			waitForVisible("graphs");
			Thread.sleep(1000);
	
			//I dont know how it works:
		verifyEquals("true", sel.getEval("window.document.getElementById('graphs').innerHTML.indexOf(\"" + graph_profile + "\") > 0"));
			/*
		 innerhtml = sel.getEval("window.document.getElementById(\"graphs\").innerHTML");
		 match = (innerhtml.contains(graph_profile)) ? true : false;
		verifyEquals("true",""+match);
		*/
		
				
		
			System.out.println("Edited Dive checked");	
		
	}

	
}