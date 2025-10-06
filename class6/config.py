import os

variable_which_i_wont_use = "this is a variable which i wont use"


class Config:
    SQLALCHEMY_DATABASE_URI = os.getenv("DB_LINK")
    SQLALCHEMY_TRACK_MODIFICATIONS = False
