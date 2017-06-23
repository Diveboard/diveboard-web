
import org.junit.Test;

import def.constant;
import diveboard.CommonActions;


public class SignInTest extends CommonActions{

	  
	@Test
	public void test_NewUser() throws Exception {
		register();
		emptyProfileCheck();
		changeProfile();
		checkProfile();
		
		settingsAcc();
		logout();
		lostPassEmail();
		accLogin();
		checkProfile();
		otherProfileView();
		closeBrowser();
	}


	private void lostPassEmail() throws InterruptedException {
		open(url+"/login/register");
		waitForElement("//div[@id='register_user_info']/input");
		
		click("id=user_submit");
		waitForElement("id=flash_notifications");
		verifyEquals(getText("id=flash_notifications"),"WARNING : Wrong login/password");
		waitForElement("//div[@id='register_user_info']/input");
		
		System.out.println("Lost password..");
		click("id=forgot_pwd");
		waitForVisible("//div[2]/div/input");
		verifyEquals("Lost password", getText("css=#lost_pwd > div.main_content_header.single_main_header > span.header_title"));
		verifyTrue(getText("css=#lost_pwd > #new_user > div.main_content_box").startsWith("Set a new password for:"));
		verifyEquals("exact:Email:", getText("css=#lost_pwd > #new_user > div.main_content_box > #register_user_info > label"));
		verifyEquals("Please Type the Two Words:", getText("css=#lost_pwd > #new_user > div.main_content_box > #register_captcha > span > label"));
		verifyTrue(isElementPresent("css=td.recaptcha_r3_c2"));
		verifyTrue(isElementPresent("//input[@id='user_submit' and @value='Reset my Password']"));
		type("//div[2]/div/input", email);
		Thread.sleep(1000);
		click("//input[@id='user_submit' and @value='Reset my Password']");
	//	click("id=register_button");
		waitForVisible("//div[@id='register_user_info']/input");
		verifyEquals(getText("id=flash_notifications"),"WARNING : An email has been sent to this address to proceed to password reset");
		
		System.out.println("Lost email..");
		click("id=forgot_email");
		waitForVisible("//div[3]/form/div[2]/div/input");
		verifyEquals("Lost email", getText("css=#lost_email > div.main_content_header.single_main_header > span.header_title"));
		verifyTrue(getText("css=#lost_email > #new_user > div.main_content_box").startsWith("If you remember your personal url, we'll be able to email you with your login."));
		verifyEquals("exact:http://www.diveboard.com/", getText("css=#lost_email > #new_user > div.main_content_box > #register_user_info > label"));
		verifyTrue(isElementPresent("link=support@diveboard.com"));
		verifyTrue(isElementPresent("document.forms[3].elements[2]"));
		verifyTrue(isElementPresent("css=#lost_email > #new_user > div.main_content_box > #register_captcha > span > label"));
		verifyTrue(isElementPresent("id=recaptcha_instructions_image"));
		verifyTrue(isElementPresent("//input[@id='user_submit' and @value='Remind me my login']"));
		type("//div[3]/form/div[2]/div/input", randomTestUsername );
		Thread.sleep(1000);
		click("//input[@id='user_submit' and @value='Remind me my login']");
	//	click("id=register_button");
		waitForVisible("//div[@id='register_user_info']/input");
		verifyEquals(getText("id=flash_notifications"),"WARNING : An email has been sent to your address with your login information");
		
		
		
	}


	private void otherProfileView() throws InterruptedException {
		System.out.println("Looking Ksso's profile..");
		open(url+"/ksso");
		waitForElement("css=div.logbook_profile_img2 > img[src='http://graph.facebook.com/v2.0/680251975/picture?type=large']");
		verifyTrue(getText("css=span.header_title").contains("Ksso"));
		verifyTrue(isElementPresent("//div[@id='sidebar']/div/div/div/a/img"));
		verifyTrue(isElementPresent("id=add_buddy"));
		verifyTrue(isElementPresent("css=img.showhome"));
		verifyTrue(isElementPresent("css=span.profile_user_badge"));
		verifyTrue(isElementPresent("css=#dive519 > a"));
		verifyEquals("Self-assessed Photography (Mar 2011)", getText("css=b"));
		verifyEquals("CMAS 2 Star (Jul 2006)", getText("//div[@id='certificates']/ul/li[3]/b"));
		verifyEquals("I learned to Scuba in summer 2005 and since then have become addicted to it. Quickly reached the freedom of the N2 FFESSM (AOW+) and started taking cool underwater pictures.\nI recently got a reflex Canon EOS 300D + Ikelite underwater housing and started to get a chance at better shots.\n\nNext objective : try to see bigger fish (I actually never saw mantas !)", getText("id=userhome_value_aboutme"));
		verifyNotEquals("0", getText("//div[@id='profile_stat']/ul/li[2]/span")); //dives published
		
	//	verifyNotEquals("0", getText("//div[@id='profile_stat']/ul/li[3]/span"));
		verifyNotEquals("0", getText("//div[@id='profile_stat']//li[3]/span[@class='half_box_data']")); //Total number of dives:
		verifyEquals("Cyprus", getText("//div[@id='profile_stat']/ul/li[4]/span"));
		verifyEquals("39.3m", getText("//div[@id='profile_stat']/ul/li[5]/span"));
		verifyEquals("Golfe Juan, France", getText("//div[@id='profile_stat']/ul/li[5]/span[2]"));
		verifyEquals("60 mins", getText("//div[@id='profile_stat']/ul/li[6]/span"));
		verifyEquals("Ko Tao, Thailand", getText("//div[@id='profile_stat']/ul/li[6]/span[2]"));
		verifyNotEquals("0", getText("//div[@id='profile_stat']/ul/li[7]/span"));
		//Number of species spotted: 
		verifyNotEquals("0", getText("//div[@id='profile_stat']/ul/li[8]/span"));
		verifyNotEquals("", getText("css=span.comment_username > a"));
		verifyNotEquals("", getText("css=div.fav_dive_body_inner > p"));
		verifyTrue(isElementPresent("css=img.triple_box_content"));
		verifyTrue(isElementPresent("//div[@id='logbook_fav_pics']/ul/li[5]/a/img"));
		verifyEquals("", getText("css=#species_spotted > ul > li > a > img.triple_box_content"));
		verifyEquals("MY CERTIFICATES", getText("css=#certificates > strong"));
		verifyEquals("Self-assessed Photography (Mar 2011)", getText("css=b"));
		verifyEquals("PADI Advanced Open Water (Jul 2006)", getText("//div[@id='certificates']/ul/li[2]/b"));
		verifyEquals("CMAS 2 Star (Jul 2006)", getText("//div[@id='certificates']/ul/li[3]/b"));
		verifyEquals("FFESSM Level 2 (Jul 2006)", getText("//div[@id='certificates']/ul/li[4]"));
		verifyEquals("CMAS 1 Star (Jul 2005)", getText("//div[@id='certificates']/ul/li[5]"));
		
		
	}








	

	private void settingsAcc() throws InterruptedException {
		openSettings();
		click("id=menu_5");
		verifyEquals("Account", getText("css=#Account > div.main_content_header.main_padded_top > span.header_title"));
		verifyEquals("Profile Settings", getText("css=#Account > div.main_content_box > span.second_lvl_header"));
		
		verifyEquals(sel.getValue("id=login_email"), email);
		
		verifyTrue(isElementPresent("id=pwd"));
		verifyTrue(isElementPresent("id=pwd_chk"));
		verifyEquals("Confirm changes", getText("//div[@id='Account']/div[2]/span[2]"));
		verifyTrue(isElementPresent("id=crnt_pwd"));
		verifyEquals("Connect your Facebook account", getText("//div[@id='Account']/div[3]/span"));
		verifyTrue(isElementPresent("css=div > a > img"));
		System.out.println("Changing pass..");
		type("id=pwd", userPassNew);
		type("id=pwd_chk", userPassNew);
		type("id=crnt_pwd", userPass);
		userPass=userPassNew;
		click("id=save_form");
		
		waitForElement("id=save_ok");
		click("id=save_form");
		waitForElement("id=save_nok");

		
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

	
	private void changeProfile() throws InterruptedException {
		System.out.println("add some info to profile..");
		click("css=img[alt=Edit]");
		waitForElement(saveDiveBut);
		type("id=userhome_edit_aboutme", "I'm another test-user!");
		type("id=userhome_edit_total_ext_dives", "10000000");
		click("css=#editable_controls2 > a.userhome_save.wizard_next");
		waitForElement("link=Cancel");
	
		
		
	}
	
	private void checkProfile() throws InterruptedException {
		System.out.println("Verifying changes..");
		waitForVisible("//div[@id='main_content_area']/div[4]/div/strong");
		Thread.sleep(3000);
		verifyEquals("I'm another test-user!", getText("id=userhome_value_aboutme"));
		verifyEquals("PLACES I'VE DIVED", getText("//div[@id='main_content_area']/div[4]/div/strong"));
		verifyEquals("FAVORITE PICTURES", getText("css=#logbook_fav_pics > strong"));
		verifyEquals("SPECIES SPOTTED:", getText("css=#species_spotted > strong"));
		verifyEquals("MY CERTIFICATES", getText("css=#certificates > strong"));
		verifyEquals("FAVORITE DIVES", getText("css=div.double_box.fav_dives > strong"));
		verifyEquals("0", getText("css=span.half_box_data"));
		verifyEquals("10000000", getText("//div[@id='profile_stat']/ul/li[3]/span"));
		verifyTrue(isElementPresent("//div[@id='plusone']/div/a"));
		verifyTrue(isElementPresent("css=span.liketext"));
		verifyTrue(isElementPresent("id=aggregateCount"));
		verifyTrue(isElementPresent("css=div.thumbs_up_icon"));
		verifyTrue(isElementPresent("//a[@id='share_this_link']/img"));
		
	}
	
}
