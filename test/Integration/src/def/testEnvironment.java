package def;
import java.util.Map;
import java.util.Set;
import java.util.Iterator;

public class testEnvironment {
	
	
	//returnes true if runs on local and false if runs on tc.diveboard.com
	public static boolean checkLocal(){
		  Map map = System.getenv();
		  Set keys = map.keySet();
		  Iterator iterator = keys.iterator();
	//  System.out.println("Variable Names:");
		  while (iterator.hasNext()){
		  String key = (String) iterator.next();
		  if (key.equals("SSH_CONNECTION"))
		  return false;
	//	  String value = (String) map.get(key);
	//	  System.out.println(key);
		 
		  }
		return true;
		  }

	//returnes http://stage.diveboard.com if not found environment variable  DB_ENV_ROOT_URL 
	// and value if get the environment variable DB_ENV_ROOT_URL
	public static String checkUrl(){
		  Map map = System.getenv();
		  Set keys = map.keySet();
		  Iterator iterator = keys.iterator();
	//  System.out.println("Variable Names:");
		  while (iterator.hasNext()){
		  String key = (String) iterator.next();
		 
		  if (key.equals("DB_ENV_ROOT_URL"))
		  return  (String) map.get(key);
	//	  System.out.println(key);
		 
		  }
		return "http://stage.diveboard.com/";
		  }
	

}
