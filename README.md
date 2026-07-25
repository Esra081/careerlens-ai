# CareerLens AI

CareerLens AI is an intelligent CV and job matching platform.

## Important Note on Job Embeddings
**Re-ingest Required**: We have updated the embedding model to `paraphrase-multilingual-MiniLM-L12-v2` for better multi-lingual and rich text support. If you have an existing database, your embeddings are invalid. You must run a new ingest to generate correct embeddings:
```bash
curl -X POST http://localhost:8000/api/v1/jobs/ingest
```
