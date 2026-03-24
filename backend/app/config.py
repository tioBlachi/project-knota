from pydantic_settings import BaseSettings, SettingsConfigDict


class Setting(BaseSettings):
    DATABASE_URL: str
    GOOGLE_ROUTES_API_KEY: str
    SUPER_SECRET_KEY: str
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRATION_MINS: int = 30

    model_config = SettingsConfigDict(
        env_file="../.env",
        env_file_encoding='utf-8',
        extra='ignore',
        )

settings = Setting()