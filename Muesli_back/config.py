import os
basedir = os.path.abspath(os.path.dirname(__file__))


#APP de init prend tout

class Config(object):

    SECRET_KEY = os.environ.get('SECRET_KEY') or 'secret'

    #Database
    SQLALCHEMY_DATABASE_URI = os.environ.get('DATABASE_URL') or \
        'sqlite:///' + os.path.join(basedir, 'app.db')
    SQLALCHEMY_TRACK_MODIFICATIONS = False

    #Pour sortie du site
    LOG_TO_STDOUT = os.environ.get('LOG_TO_STDOUT')

#from microblog import app
#app.config['SECRET_KEY']
