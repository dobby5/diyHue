import logManager
import configManager
from lights.protocols import protocols
from time import sleep
from lights.manage import updateGroupStats
from datetime import datetime

logging = logManager.logger.get_logger(__name__)
bridgeConfig = configManager.bridgeConfig.yaml_config

def syncWithLights(off_if_unreachable): #update Hue Bridge lights states
    while True:
        logging.info("start lights sync")
        for key, light in bridgeConfig["lights"].items():
            protocol_name = light.protocol
            for protocol in protocols:
                if "lights.protocols." + protocol_name == protocol.__name__:
                    try:
                        logging.debug("fetch " + light.name)
                        newState = protocol.get_light_state(light)
                        logging.debug(newState)
                        light.state["reachable"] = True
                    except Exception as e:
                        light.state["reachable"] = False
                        if off_if_unreachable:
                            light.state["on"] = False
                        logging.warning(light.name + " is unreachable: %s", e)
            #updateGroupStats(light, lights, groups)

        sleep(10) #wait at last 10 seconds before next sync
        i = 0
        while i < 300: #sync with lights every 300 seconds or instant if one user is connected
            for key, user in bridgeConfig["apiUsers"].items():
                lu = user.last_use_date
                try: #in case if last use is not a proper datetime
                    lu = datetime.strptime(lu, "%Y-%m-%dT%H:%M:%S")
                    if abs(datetime.now() - lu) <= timedelta(seconds = 2):
                        i = 300
                        break
                except:
                    pass
            i += 1
            sleep(1)