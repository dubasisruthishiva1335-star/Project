import { Body, Controller, Param, Post, Put, Req, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { Roles, RolesGuard } from '../auth/roles.guard';
import { StorageService } from '../common/storage.service';
import { PresignDto } from './dto/presign.dto';

/**
 * Shared upload plumbing used by every admin content page:
 *  1. POST /admin/uploads/presign   -> { uploadUrl, s3Key, publicUrl, direct }
 *  2. Frontend PUTs the file bytes to `uploadUrl`
 *     - if `direct` is true, that's a real S3 presigned URL (production)
 *     - if `direct` is false, it's this API's own /admin/uploads/local/:key
 *       receiver (local dev, no AWS account needed)
 *  3. Frontend POSTs the rest of the metadata + s3Key to the domain's
 *     own /admin/<domain>/confirm endpoint (see notes/results/job-listings
 *     controllers below).
 */
@ApiTags('admin-uploads')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('ADMIN', 'SUPER_ADMIN')
@Controller('admin/uploads')
export class UploadsController {
  constructor(private storage: StorageService) {}

  @Post('presign')
  presign(@Body() dto: PresignDto) {
    return this.storage.presign(dto.domain, dto.fileName, dto.contentType);
  }

  // Local-dev-only receiver: accepts raw bytes at the key issued by presign().
  // In production (STORAGE_DRIVER=s3) this route is never used — the
  // frontend PUTs straight to S3 instead.
  @Put('local/:key')
  async receiveLocal(@Param('key') key: string, @Req() req: any) {
    const chunks: Buffer[] = [];
    for await (const chunk of req) chunks.push(chunk);
    const buffer = Buffer.concat(chunks);
    const url = await this.storage.writeLocalFile(decodeURIComponent(key), buffer);
    return { ok: true, url };
  }
}
