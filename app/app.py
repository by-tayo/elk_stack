import logging
import random
import time

logging.basicConfig(
    filename="/logs/app.log",
    level=logging.INFO,
    format="%(levelname)s %(asctime)s %(message)s"
)

while True:
    user_id = random.randint(1, 500)
    latency_ms = random.randint(20, 400)
    logging.info("User login successful user_id=%d latency_ms=%d", user_id, latency_ms)
    logging.warning("CPU usage high latency_ms=%d", random.randint(400, 900))
    logging.error("Database connection failed user_id=%d", user_id)
    time.sleep(5)
