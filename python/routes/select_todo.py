from fastapi import APIRouter
from fastapi.responses import Response
from database import connect

router = APIRouter()

@router.get("/select")
async def select():
  conn = connect()
  curs = conn.cursor()

  sql = """
        SELECT seq, content, insertdate
        FROM imagetodolist
        ORDER BY insertdate DESC, seq DESC
        """

  curs.execute(sql)
  rows = curs.fetchall()
  conn.close()

  result = [{'seq': row[0], 'content': row[1], 'insertdate': row[2]} for row in rows]

  return {'results': result}

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