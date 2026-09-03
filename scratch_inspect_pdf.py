import sys

try:
    import pypdf
    reader = pypdf.PdfReader('ProposalSample.pdf')
    print('Total pages:', len(reader.pages))
    for i, page in enumerate(reader.pages):
        print(f"Page {i+1}: size=({page.mediabox.width}, {page.mediabox.height}), images={len(page.images)}")
        if i == 0 and len(page.images) > 0:
            for img_name, img_file in page.images.items():
                print(f"  Img: {img_name}, size={len(img_file.data)} bytes")
except Exception as e:
    print('Error with pypdf:', e)
