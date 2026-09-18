from fastapi import FastAPI

from routes.delete_todo import router as delete_todo_router
from routes.insert_todo import router as insert_todo_router
from routes.select_todo import router as select_todo_router
from routes.update_todo import router as update_todo_router

app = FastAPI(title="Image Todo List API")

# /todos 주소를 기능별 router 파일로 전달한다.
app.include_router(select_todo_router, prefix="/todos", tags=["todos-select"])
app.include_router(insert_todo_router, prefix="/todos", tags=["todos-insert"])
app.include_router(update_todo_router, prefix="/todos", tags=["todos-update"])
app.include_router(delete_todo_router, prefix="/todos", tags=["todos-delete"])


@app.get("/")
async def health_check():
    return {"message": "Image Todo List API"}


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="192.168.20.52", port=8000)

