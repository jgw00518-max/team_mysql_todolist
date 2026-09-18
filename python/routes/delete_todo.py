import pymysql
from fastapi import APIRouter, HTTPException

from database import connect

router = APIRouter()


def prepare_deleted_todos_table():
    """삭제된 Todo와 이미지 연결을 보관할 휴지통 테이블을 준비한다."""
    conn = connect()
    try:
        with conn.cursor() as curs:
            curs.execute(
                """
                CREATE TABLE IF NOT EXISTS deleted_todos (
                    seq INT PRIMARY KEY,
                    content VARCHAR(45),
                    insertdate DATETIME,
                    image_seq INT,
                    delete_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
                )
                """
            )
        conn.commit()
    finally:
        conn.close()


@router.on_event("startup")
def prepare_database():
    prepare_deleted_todos_table()


@router.post("/trash/{seq}/restore")
async def restore_todo(seq: int):
    """휴지통 Todo를 기존 번호와 이미지 연결로 복구한다."""
    conn = None
    try:
        conn = connect()
        with conn.cursor() as curs:
            curs.execute(
                """
                SELECT seq, content, insertdate, image_seq
                FROM deleted_todos
                WHERE seq = %s
                FOR UPDATE
                """,
                (seq,),
            )
            deleted_todo = curs.fetchone()
            if deleted_todo is None:
                raise HTTPException(
                    status_code=404,
                    detail="복구할 Todo를 찾을 수 없습니다.",
                )

            curs.execute("SELECT seq FROM imagetodolist WHERE seq = %s", (seq,))
            if curs.fetchone() is not None:
                raise HTTPException(
                    status_code=409,
                    detail="같은 번호의 Todo가 있어 복구할 수 없습니다.",
                )

            curs.execute(
                """
                INSERT INTO imagetodolist (seq, content, insertdate)
                VALUES (%s, %s, %s)
                """,
                deleted_todo[:3],
            )

            image_seq = deleted_todo[3]
            if image_seq is not None:
                curs.execute(
                    """
                    INSERT INTO selection (image_seq, imagetodolist_seq)
                    VALUES (%s, %s)
                    """,
                    (image_seq, seq),
                )

            curs.execute("DELETE FROM deleted_todos WHERE seq = %s", (seq,))

        conn.commit()
        return {"result": "OK", "seq": seq}
    except HTTPException:
        if conn is not None:
            conn.rollback()
        raise
    except pymysql.MySQLError as error:
        if conn is not None:
            conn.rollback()
        print("Restore todo error:", error)
        raise HTTPException(
            status_code=500,
            detail="Todo 복구에 실패했습니다.",
        ) from error
    finally:
        if conn is not None:
            conn.close()


@router.post("/trash/{seq}")
async def move_todo_to_trash(seq: int):
    """Todo와 선택 이미지를 휴지통으로 이동한다."""
    conn = None
    try:
        conn = connect()
        with conn.cursor() as curs:
            curs.execute(
                """
                SELECT t.seq, t.content, t.insertdate, s.image_seq
                FROM imagetodolist AS t
                LEFT JOIN selection AS s ON s.imagetodolist_seq = t.seq
                WHERE t.seq = %s
                FOR UPDATE
                """,
                (seq,),
            )
            todo = curs.fetchone()
            if todo is None:
                raise HTTPException(
                    status_code=404,
                    detail="삭제할 Todo를 찾을 수 없습니다.",
                )

            curs.execute(
                """
                INSERT INTO deleted_todos
                    (seq, content, insertdate, image_seq, delete_time)
                VALUES (%s, %s, %s, %s, NOW())
                """,
                todo,
            )
            curs.execute(
                "DELETE FROM selection WHERE imagetodolist_seq = %s",
                (seq,),
            )
            curs.execute("DELETE FROM imagetodolist WHERE seq = %s", (seq,))

        conn.commit()
        return {"result": "OK", "seq": seq}
    except HTTPException:
        if conn is not None:
            conn.rollback()
        raise
    except pymysql.MySQLError as error:
        if conn is not None:
            conn.rollback()
        print("Move todo to trash error:", error)
        raise HTTPException(
            status_code=500,
            detail="Todo 삭제에 실패했습니다.",
        ) from error
    finally:
        if conn is not None:
            conn.close()


@router.get("/trash")
async def select_deleted_todos():
    """최근 삭제 순서로 휴지통 목록을 조회한다."""
    conn = None
    try:
        conn = connect()
        with conn.cursor() as curs:
            curs.execute(
                """
                SELECT seq, content, insertdate, image_seq, delete_time
                FROM deleted_todos
                ORDER BY delete_time DESC, seq DESC
                """
            )
            rows = curs.fetchall()

        results = [
            {
                "seq": row[0],
                "content": row[1],
                "insertdate": row[2],
                "image_seq": row[3],
                "delete_time": row[4],
            }
            for row in rows
        ]
        return {"results": results}
    except pymysql.MySQLError as error:
        print("Select deleted todos error:", error)
        raise HTTPException(
            status_code=500,
            detail="휴지통 조회에 실패했습니다.",
        ) from error
    finally:
        if conn is not None:
            conn.close()
