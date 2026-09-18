from fastapi import APIRouter, HTTPException
from database import connect

router = APIRouter()


def prepare_selection_compatibility():
    """Keep the existing select_todo.py query compatible with the DB schema."""
    conn = connect()
    cursor = conn.cursor()

    try:
        cursor.execute(
            """
            CREATE OR REPLACE VIEW collect AS
            SELECT image_seq, imagetodolist_seq AS todolist_seq
            FROM selection
            """
        )

        cursor.execute(
            """
            INSERT INTO selection (image_seq, imagetodolist_seq)
            SELECT i.seq, t.seq
            FROM image AS i
            JOIN imagetodolist AS t ON t.seq = i.seq
            WHERE NOT EXISTS (
                SELECT 1
                FROM selection AS s
                WHERE s.imagetodolist_seq = t.seq
            )
            """
        )
        conn.commit()
    except Exception:
        conn.rollback()
        raise
    finally:
        cursor.close()
        conn.close()


@router.on_event("startup")
def prepare_database():
    prepare_selection_compatibility()




@router.post("/insertTodo")
async def insert_todo(content: str, image_seq: int):
    conn = connect()
    cursor = conn.cursor()

    try:
        # 1. 할 일 내용 저장
        sql = """
            INSERT INTO imagetodolist (content, insertdate)
            VALUES (%s, NOW())
        """
        cursor.execute(sql, (content,))

        # 방금 추가된 imagetodolist의 seq
        todolist_seq = cursor.lastrowid

        # 2. 선택한 이미지와 할 일을 연결
        sql = """
            INSERT INTO selection (image_seq, imagetodolist_seq)
            VALUES (%s, %s)
        """
        cursor.execute(sql, (image_seq, todolist_seq))

        conn.commit()

        return {
            "result": "OK",
            "todolist_seq": todolist_seq
        }

    except Exception as error:
        conn.rollback()

        print("insertTodo Error:", error)
        raise HTTPException(
            status_code=500,
            detail="Todo registration failed. Check the FastAPI server log.",
        ) from error

    finally:
        cursor.close()
        conn.close()
