import time
import logging

logging.basicConfig(
    filename="/logs/app.log",
    level=logging.INFO,
    format="%(levelname)s %(asctime)s %(message)s"
)

while True:
    logging.info("User login successful user_id=42")
    logging.warning("CPU usage high")
    logging.error("Database connection failed")
    time.sleep(5)