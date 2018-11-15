from flask import Flask
from config import Config

#Database
from flask_sqlalchemy import SQLAlchemy
from flask_migrate import Migrate


app = Flask(__name__)
app.config.from_object(Config)


#Database
db = SQLAlchemy(app)
migrate = Migrate(app, db)

from app import routes, models
