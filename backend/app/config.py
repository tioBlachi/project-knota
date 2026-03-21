from pydantic_settings import BaseSettings, SettingsConfigDict


class Setting(BaseSettings):
    DATABASE_URL: str
    GOOGLE_ROUTES_API_KEY: str

    model_config = SettingsConfigDict(
        env_file="../.env",
        env_file_encoding='utf-8',
        extra='ignore',
        )

settings = Setting()