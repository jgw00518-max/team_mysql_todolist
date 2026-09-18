from datetime import date

import pymysql
from fastapi import APIRouter, Form, HTTPException

from database import connect

router = APIRouter()


@router.put("/{seq}")
async def update_todo(
    seq: int,
    content: str = Form(..., max_length=45),
    insertdate: date = Form(...),
    image_seq: int | None = Form(None),
):
    """Todo 내용과 날짜를 수정하고 선택한 경우에만 이미지 연결을 바꾼다."""
    normalized_content = content.strip()
    if not normalized_content:
        raise HTTPException(status_code=400, detail="내용을 입력해 주세요.")

    conn = None
    try:
        conn = connect()
        with conn.cursor() as curs:
            curs.execute(
                """
                UPDATE imagetodolist
                SET content = %s, insertdate = %s
                WHERE seq = %s
                """,
                (normalized_content, insertdate, seq),
            )

            if curs.rowcount == 0:
                curs.execute(
                    "SELECT seq FROM imagetodolist WHERE seq = %s",
                    (seq,),
                )
                if curs.fetchone() is None:
                    raise HTTPException(
                        status_code=404,
                        detail="수정할 Todo를 찾을 수 없습니다.",
                    )

            if image_seq is not None:
                curs.execute("SELECT seq FROM image WHERE seq = %s", (image_seq,))
                if curs.fetchone() is None:
                    raise HTTPException(
                        status_code=404,
                        detail="선택한 이미지를 찾을 수 없습니다.",
                    )

                curs.execute(
                    "DELETE FROM selection WHERE imagetodolist_seq = %s",
                    (seq,),
                )
                curs.execute(
                    """
                    INSERT INTO selection (image_seq, imagetodolist_seq)
                    VALUES (%s, %s)
                    """,
                    (image_seq, seq),
                )

        conn.commit()
        return {"result": "OK", "seq": seq, "image_seq": image_seq}
    except HTTPException:
        if conn is not None:
            conn.rollback()
        raise
    except pymysql.MySQLError as error:
        if conn is not None:
            conn.rollback()
        print("Update todo error:", error)
        raise HTTPException(
            status_code=500,
            detail="Todo 수정에 실패했습니다.",
        ) from error
    finally:
        if conn is not None:
            conn.close()
