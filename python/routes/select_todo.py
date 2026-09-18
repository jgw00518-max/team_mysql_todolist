from fastapi import APIRouter
from fastapi.responses import Response
from database import connect

router = APIRouter()

@router.get("/select")
async def select():
  conn = connect()
  curs = conn.cursor()

  sql = """
        SELECT t.seq, t.content, t.insertdate, s.image_seq
        FROM imagetodolist AS t
        LEFT JOIN selection AS s ON s.imagetodolist_seq = t.seq
        ORDER BY t.insertdate DESC, t.seq DESC
        """

  curs.execute(sql)
  rows = curs.fetchall()
  conn.close()

  result = [
    {
      'seq': row[0],
      'content': row[1],
      'insertdate': row[2],
      'image_seq': row[3],
    }
    for row in rows
  ]

  return {'results': result}

@router.get("/image/{image_seq}")
async def view_image(image_seq: int):
  """이미지 번호에 해당하는 원본 이미지를 반환한다."""
  conn = connect()
  curs = conn.cursor()

  try:
    curs.execute("SELECT image FROM image WHERE seq = %s", (image_seq,))
    row = curs.fetchone()

    if row and row[0]:
      return Response(
        content=row[0],
        media_type="image/png",
        headers={"Cache-Control": "no-cache, no-store, must-revalidate"}
      )

    return {'result': 'Image Not Found'}
  finally:
    curs.close()
    conn.close()

@router.get("/view/{seq}")
async def view(seq: int):
  try:
    conn = connect()
    curs = conn.cursor()

    # curs.execute("SELECT image FROM image WHERE seq = %s", (seq,))
    curs.execute("""SELECT i.image 
          FROM collect AS c 
          JOIN image AS i ON c.image_seq = i.seq 
          WHERE c.todolist_seq = %s
          """, (seq,))
    row = curs.fetchone()
    conn.close()

    if row and row[0]:
      return Response(
        content=row[0],
        media_type="image/png",
        headers={"Cache-Control": "no-cache, no-store, must-revalidate"}
      )
    else:
      return {'result': 'Image Not Found'}

  except Exception as e:
    print("Error:", e)
    return {'result': 'Error'}
